import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class HttpClient {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': AppConstants.userAgent,
    },
  ));

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyToken);
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // GET请求
  static Future<Response> get(String url, {Map<String, dynamic>? params}) async {
    final fullUrl = url.startsWith('http') ? url : '${AppConstants.fullApiBase}$url';
    final headers = await getAuthHeaders();
    return _dio.get(fullUrl, queryParameters: params, options: Options(headers: headers));
  }

  // POST请求
  static Future<Response> post(String url, {dynamic data}) async {
    final fullUrl = url.startsWith('http') ? url : '${AppConstants.fullApiBase}$url';
    final headers = await getAuthHeaders();
    return _dio.post(fullUrl, data: data, options: Options(headers: headers));
  }

  // PUT请求
  static Future<Response> put(String url, {dynamic data}) async {
    final fullUrl = url.startsWith('http') ? url : '${AppConstants.fullApiBase}$url';
    final headers = await getAuthHeaders();
    return _dio.put(fullUrl, data: data, options: Options(headers: headers));
  }

  // DELETE请求
  static Future<Response> delete(String url) async {
    final fullUrl = url.startsWith('http') ? url : '${AppConstants.fullApiBase}$url';
    final headers = await getAuthHeaders();
    return _dio.delete(fullUrl, options: Options(headers: headers));
  }

  // 流式请求（SSE）
  static Future<void> stream(
    String url, {
    dynamic data,
    required void Function(String) onMessage,
    void Function(dynamic)? onError,
    void Function()? onDone,
  }) async {
    final fullUrl = url.startsWith('http') ? url : '${AppConstants.fullApiBase}$url';
    final headers = await getAuthHeaders();
    headers['Accept'] = 'text/event-stream';
    
    try {
      final response = await _dio.post(
        fullUrl,
        data: data,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
        ),
      );

      await (response.data as ResponseBody).stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
        if (line.startsWith('data: ')) {
          onMessage(line.substring(6));
        }
      });
      onDone?.call();
    } catch (e) {
      onError?.call(e);
    }
  }

  // 下载文件
  static Future<Response> download(String url, String savePath, {void Function(int, int)? onProgress}) async {
    return _dio.download(url, savePath, onReceiveProgress: onProgress);
  }
}
