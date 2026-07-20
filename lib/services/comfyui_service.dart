import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

/// ComfyUI 连接服务
/// 连接本地 ComfyUI (默认 http://127.0.0.1:8188)
/// Handles the full lifecycle: submit workflow, poll for completion, download image.
class ComfyUiService {
  final String serverAddress;
  final Dio _dio;
  static const int _defaultTimeoutMs = 600000; // 10 minutes
  static const int _pollIntervalMs = 2000;

  ComfyUiService({
    this.serverAddress = '127.0.0.1:8188',
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 600);
    _dio.options.sendTimeout = const Duration(seconds: 30);
  }

  String get baseUrl => 'http://$serverAddress';

  // ─── Public API ───

  /// txt2img 生图
  Future<GenerationResult> generateTxt2Img({
    required String prompt,
    String negativePrompt = '',
    required int width,
    required int height,
    int steps = 20,
    double cfg = 7.0,
    int? seed,
    String samplerName = 'euler',
    String schedulerName = 'simple',
  }) async {
    final actualSeed = seed ?? DateTime.now().millisecondsSinceEpoch;

    final workflow = _buildTxt2ImgWorkflow(
      prompt: prompt,
      negativePrompt: negativePrompt,
      width: width,
      height: height,
      steps: steps,
      cfg: cfg,
      seed: actualSeed,
      samplerName: samplerName,
      schedulerName: schedulerName,
    );

    final promptId = await _submitPrompt(workflow);

    final result = await _pollHistory(promptId);
    final (filename, subfolder, type) = _parseOutputInfo(result);

    final imageBytes = await _downloadImage(filename, subfolder, type);
    return GenerationResult(
      imageBytes: imageBytes,
      seed: actualSeed,
      promptId: promptId,
    );
  }

  /// img2img 生图
  Future<GenerationResult> generateImg2Img({
    required String prompt,
    String negativePrompt = '',
    required int width,
    required int height,
    int steps = 20,
    double cfg = 7.0,
    int? seed,
    required Uint8List sourceImageBytes,
    double denoiseStrength = 0.6,
    String samplerName = 'euler',
    String schedulerName = 'simple',
  }) async {
    final actualSeed = seed ?? DateTime.now().millisecondsSinceEpoch;

    // Upload source image first
    final filename = await uploadImage(sourceImageBytes, 'localdream_input.png');

    final workflow = _buildImg2ImgWorkflow(
      prompt: prompt,
      negativePrompt: negativePrompt,
      width: width,
      height: height,
      steps: steps,
      cfg: cfg,
      seed: actualSeed,
      inputFilename: filename,
      denoiseStrength: denoiseStrength,
      samplerName: samplerName,
      schedulerName: schedulerName,
    );

    final promptId = await _submitPrompt(workflow);
    final result = await _pollHistory(promptId);
    final (outFilename, subfolder, type) = _parseOutputInfo(result);

    final imageBytes = await _downloadImage(outFilename, subfolder, type);
    return GenerationResult(
      imageBytes: imageBytes,
      seed: actualSeed,
      promptId: promptId,
    );
  }

  // ─── Low-level API ───

  /// POST /prompt - 提交工作流
  Future<String> _submitPrompt(Map<String, dynamic> workflow) async {
    final payload = {'prompt': workflow};
    final resp = await _dio.post(
      '$baseUrl/prompt',
      data: payload,
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = resp.data as Map<String, dynamic>;
    final promptId = data['prompt_id'] as String?;
    if (promptId == null || promptId.isEmpty) {
      throw ComfyUiException('ComfyUI did not return a prompt_id');
    }
    return promptId;
  }

  /// GET /history/{prompt_id} - 轮询直到完成
  Future<Map<String, dynamic>> _pollHistory(
    String promptId, {
    int timeoutMs = _defaultTimeoutMs,
  }) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    final url = '$baseUrl/history/$promptId';

    while (DateTime.now().isBefore(deadline)) {
      try {
        final resp = await _dio.get(url);
        final json = resp.data as Map<String, dynamic>;
        if (json.containsKey(promptId)) {
          final result = json[promptId] as Map<String, dynamic>;
          final statusObj = result['status'] as Map<String, dynamic>?;
          final statusStr = statusObj?['status_str'] as String? ?? '';
          if (statusStr == 'success' || result.containsKey('outputs')) {
            return result;
          }
        }
      } catch (_) {
        // keep polling
      }
      await Future.delayed(const Duration(milliseconds: _pollIntervalMs));
    }

    throw ComfyUiException(
      'ComfyUI timeout: prompt $promptId did not complete within ${timeoutMs}ms',
    );
  }

  /// GET /view - 下载生成的图片
  Future<Uint8List> _downloadImage(
    String filename,
    String subfolder,
    String type,
  ) async {
    final url = '$baseUrl/view?'
        'filename=${Uri.encodeComponent(filename)}'
        '&subfolder=${Uri.encodeComponent(subfolder)}'
        '&type=${Uri.encodeComponent(type)}';

    final resp = await _dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(resp.data as List<int>);
  }

  /// POST /upload/image - 上传图片
  Future<String> uploadImage(
    Uint8List imageBytes,
    String filename,
  ) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        imageBytes,
        filename: filename,
        contentType: MediaType('image', 'png'),
      ),
      'subfolder': '',
      'type': 'input',
    });

    final resp = await _dio.post(
      '$baseUrl/upload/image',
      data: formData,
    );
    final data = resp.data as Map<String, dynamic>;
    return data['name'] as String? ?? filename;
  }

  /// 健康检查
  Future<bool> healthCheck() async {
    try {
      final resp = await _dio.get(
        '$baseUrl/system_stats',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 获取系统信息
  Future<Map<String, dynamic>?> getSystemStats() async {
    try {
      final resp = await _dio.get('$baseUrl/system_stats');
      return resp.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// 获取队列信息
  Future<Map<String, dynamic>?> getQueue() async {
    try {
      final resp = await _dio.get('$baseUrl/queue');
      return resp.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ─── Workflow Builders (FLUX.2 Klein 9B) ───

  List<dynamic> _nodeRef(String nodeId, {int outputIndex = 0}) =>
      [nodeId, outputIndex];

  Map<String, dynamic> _buildTxt2ImgWorkflow({
    required String prompt,
    required String negativePrompt,
    required int width,
    required int height,
    required int steps,
    required double cfg,
    required int seed,
    required String samplerName,
    required String schedulerName,
  }) {
    return {
      '1': {
        'class_type': 'UNETLoader',
        'inputs': {
          'unet_name': 'flux-2-klein-9b-fp8.safetensors',
          'weight_dtype': 'fp8_e4m3fn',
        },
      },
      '2': {
        'class_type': 'CLIPLoader',
        'inputs': {
          'clip_name': 'qwen_3_8b_fp8mixed.safetensors',
          'type': 'flux2',
        },
      },
      '3': {
        'class_type': 'VAELoader',
        'inputs': {
          'vae_name': 'flux2-vae.safetensors',
        },
      },
      '4': {
        'class_type': 'ModelSamplingFlux',
        'inputs': {
          'model': _nodeRef('1'),
          'max_shift': 1.15,
          'base_shift': 0.5,
          'width': width,
          'height': height,
        },
      },
      '5': {
        'class_type': 'CLIPTextEncode',
        'inputs': {
          'text': prompt,
          'clip': _nodeRef('2'),
        },
      },
      '6': {
        'class_type': 'CLIPTextEncode',
        'inputs': {
          'text': negativePrompt,
          'clip': _nodeRef('2'),
        },
      },
      '7': {
        'class_type': 'EmptyFlux2LatentImage',
        'inputs': {
          'width': width,
          'height': height,
          'batch_size': 1,
        },
      },
      '8': {
        'class_type': 'FluxGuidance',
        'inputs': {
          'conditioning': _nodeRef('5'),
          'guidance': 3.5,
        },
      },
      '9': {
        'class_type': 'Flux2Scheduler',
        'inputs': {
          'steps': steps,
          'width': width,
          'height': height,
        },
      },
      '10': {
        'class_type': 'KSamplerSelect',
        'inputs': {
          'sampler_name': samplerName,
        },
      },
      '11': {
        'class_type': 'SamplerCustom',
        'inputs': {
          'model': _nodeRef('4'),
          'add_noise': true,
          'noise_seed': seed,
          'cfg': 1.0,
          'positive': _nodeRef('8'),
          'negative': _nodeRef('6'),
          'sampler': _nodeRef('10'),
          'sigmas': _nodeRef('9'),
          'latent_image': _nodeRef('7'),
        },
      },
      '12': {
        'class_type': 'VAEDecode',
        'inputs': {
          'samples': _nodeRef('11'),
          'vae': _nodeRef('3'),
        },
      },
      '13': {
        'class_type': 'SaveImage',
        'inputs': {
          'filename_prefix': 'localdream',
          'images': _nodeRef('12'),
        },
      },
    };
  }

  Map<String, dynamic> _buildImg2ImgWorkflow({
    required String prompt,
    required String negativePrompt,
    required int width,
    required int height,
    required int steps,
    required double cfg,
    required int seed,
    required String inputFilename,
    required double denoiseStrength,
    required String samplerName,
    required String schedulerName,
  }) {
    return {
      '1': {
        'class_type': 'UNETLoader',
        'inputs': {
          'unet_name': 'flux-2-klein-9b-fp8.safetensors',
          'weight_dtype': 'fp8_e4m3fn',
        },
      },
      '2': {
        'class_type': 'CLIPLoader',
        'inputs': {
          'clip_name': 'qwen_3_8b_fp8mixed.safetensors',
          'type': 'flux2',
        },
      },
      '3': {
        'class_type': 'VAELoader',
        'inputs': {
          'vae_name': 'flux2-vae.safetensors',
        },
      },
      '4': {
        'class_type': 'ModelSamplingFlux',
        'inputs': {
          'model': _nodeRef('1'),
          'max_shift': 1.15,
          'base_shift': 0.5,
          'width': width,
          'height': height,
        },
      },
      '5': {
        'class_type': 'CLIPTextEncode',
        'inputs': {
          'text': prompt,
          'clip': _nodeRef('2'),
        },
      },
      '6': {
        'class_type': 'CLIPTextEncode',
        'inputs': {
          'text': negativePrompt,
          'clip': _nodeRef('2'),
        },
      },
      '11': {
        'class_type': 'LoadImage',
        'inputs': {
          'image': inputFilename,
        },
      },
      '12': {
        'class_type': 'VAEEncode',
        'inputs': {
          'pixels': _nodeRef('11'),
          'vae': _nodeRef('3'),
        },
      },
      '8': {
        'class_type': 'FluxGuidance',
        'inputs': {
          'conditioning': _nodeRef('5'),
          'guidance': 3.5,
        },
      },
      '9': {
        'class_type': 'Flux2Scheduler',
        'inputs': {
          'steps': steps,
          'width': width,
          'height': height,
        },
      },
      '10': {
        'class_type': 'KSamplerSelect',
        'inputs': {
          'sampler_name': samplerName,
        },
      },
      '13': {
        'class_type': 'SamplerCustom',
        'inputs': {
          'model': _nodeRef('4'),
          'add_noise': true,
          'noise_seed': seed,
          'cfg': 1.0,
          'positive': _nodeRef('8'),
          'negative': _nodeRef('6'),
          'sampler': _nodeRef('10'),
          'sigmas': _nodeRef('9'),
          'latent_image': _nodeRef('12'),
        },
      },
      '14': {
        'class_type': 'VAEDecode',
        'inputs': {
          'samples': _nodeRef('13'),
          'vae': _nodeRef('3'),
        },
      },
      '15': {
        'class_type': 'SaveImage',
        'inputs': {
          'filename_prefix': 'localdream',
          'images': _nodeRef('14'),
        },
      },
    };
  }

  // ─── Output parsing ───

  (String, String, String) _parseOutputInfo(Map<String, dynamic> historyEntry) {
    final outputs = historyEntry['outputs'] as Map<String, dynamic>?;
    if (outputs == null) {
      throw ComfyUiException('No outputs in ComfyUI history entry');
    }

    for (final entry in outputs.entries) {
      final nodeOutput = entry.value as Map<String, dynamic>;
      final images = nodeOutput['images'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        final img = images.first as Map<String, dynamic>;
        return (
          img['filename'] as String,
          img['subfolder'] as String? ?? '',
          img['type'] as String? ?? 'output',
        );
      }
    }
    throw ComfyUiException('No image found in ComfyUI outputs');
  }

  void dispose() {
    _dio.close();
  }
}

/// 生成结果
class GenerationResult {
  final Uint8List imageBytes;
  final int seed;
  final String promptId;

  GenerationResult({
    required this.imageBytes,
    required this.seed,
    required this.promptId,
  });
}

/// ComfyUI 异常
class ComfyUiException implements Exception {
  final String message;
  ComfyUiException(this.message);

  @override
  String toString() => message;
}
