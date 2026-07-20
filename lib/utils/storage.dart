import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageUtil {
  static Future<SharedPreferences> get _prefs async => 
      await SharedPreferences.getInstance();

  // String
  static Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  // Int
  static Future<void> setInt(String key, int value) async {
    final prefs = await _prefs;
    await prefs.setInt(key, value);
  }

  static Future<int?> getInt(String key) async {
    final prefs = await _prefs;
    return prefs.getInt(key);
  }

  // Bool
  static Future<void> setBool(String key, bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await _prefs;
    return prefs.getBool(key);
  }

  // List<String>
  static Future<void> setStringList(String key, List<String> value) async {
    final prefs = await _prefs;
    await prefs.setStringList(key, value);
  }

  static Future<List<String>?> getStringList(String key) async {
    final prefs = await _prefs;
    return prefs.getStringList(key);
  }

  // JSON对象
  static Future<void> setJson(String key, dynamic value) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<T?> getJson<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final prefs = await _prefs;
    final str = prefs.getString(key);
    if (str == null) return null;
    try {
      return fromJson(jsonDecode(str) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  static Future<List<T>> getJsonList<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final prefs = await _prefs;
    final str = prefs.getString(key);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // 删除
  static Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  // 清空
  static Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
