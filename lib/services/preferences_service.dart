import 'package:shared_preferences/shared_preferences.dart';

/// 偏好设置服务 - 封装 SharedPreferences 读写
class PreferencesService {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<String> getString(String key, {String defaultValue = ''}) async {
    final p = await _prefs;
    return p.getString(key) ?? defaultValue;
  }

  static Future<void> setString(String key, String value) async {
    final p = await _prefs;
    await p.setString(key, value);
  }

  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    final p = await _prefs;
    return p.getInt(key) ?? defaultValue;
  }

  static Future<void> setInt(String key, int value) async {
    final p = await _prefs;
    await p.setInt(key, value);
  }

  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final p = await _prefs;
    return p.getBool(key) ?? defaultValue;
  }

  static Future<void> setBool(String key, bool value) async {
    final p = await _prefs;
    await p.setBool(key, value);
  }

  static Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    final p = await _prefs;
    return p.getDouble(key) ?? defaultValue;
  }

  static Future<void> setDouble(String key, double value) async {
    final p = await _prefs;
    await p.setDouble(key, value);
  }
}
