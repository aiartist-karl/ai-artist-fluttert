import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  static const uuid = Uuid();
  
  // 保存图片到本地
  static Future<String> saveImage(Uint8List bytes, {String? prefix}) async {
    final dir = await getApplicationDocumentsDirectory();
    final name = '${prefix ?? 'img'}_${DateTime.now().millisecondsSinceEpoch}_${uuid.v4().substring(0, 8)}.png';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // 压缩图片
  static Future<Uint8List> compressImage(Uint8List bytes, {int quality = 85, int? maxWidth}) async {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    
    var resized = image;
    if (maxWidth != null && image.width > maxWidth) {
      resized = img.copyResize(image, width: maxWidth);
    }
    
    final compressed = img.encodePng(resized, level: quality);
    return Uint8List.fromList(compressed);
  }

  // 获取图片尺寸
  static Future<(int, int)> getImageSize(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) return (0, 0);
    return (image.width, image.height);
  }

  // 裁剪图片
  static Future<Uint8List> cropImage(Uint8List bytes, {int x = 0, int y = 0, int? width, int? height}) async {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    
    final cropped = img.copyCrop(
      image,
      x: x,
      y: y,
      width: width ?? image.width,
      height: height ?? image.height,
    );
    return Uint8List.fromList(img.encodePng(cropped));
  }

  // Base64编码
  static String toBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  // Base64解码
  static Uint8List fromBase64(String base64Str) {
    return base64Decode(base64Str);
  }
}
