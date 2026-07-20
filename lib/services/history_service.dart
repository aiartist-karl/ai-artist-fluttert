import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_item.dart';

/// 历史记录服务
class HistoryService {
  static const String _keyHistoryList = 'history_items';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// 从 SharedPreferences 加载全部历史记录
  static Future<List<HistoryItem>> _loadAll() async {
    final prefs = await _prefs;
    final json = prefs.getString(_keyHistoryList);
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 保存全部历史记录到 SharedPreferences
  static Future<void> _saveAll(List<HistoryItem> items) async {
    final prefs = await _prefs;
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_keyHistoryList, json);
  }

  /// 加载指定模型的历史记录
  static Future<List<HistoryItem>> loadHistoryForModel(String modelId) async {
    final all = await _loadAll();
    return all.where((item) => item.modelId == modelId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 加载历史记录（支持筛选）
  static Future<List<HistoryItem>> loadHistory({String? modelId, bool? favoriteOnly}) async {
    final all = await _loadAll();
    var filtered = all;
    if (modelId != null) {
      filtered = filtered.where((item) => item.modelId == modelId).toList();
    }
    if (favoriteOnly == true) {
      filtered = filtered.where((item) => item.favorite).toList();
    }
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  /// 查询历史记录（支持多条件筛选）
  static Future<List<HistoryItem>> queryHistory({
    Set<String>? modelIds,
    Set<String>? schedulers,
    Set<String>? sizes,
    bool favoritesOnly = false,
  }) async {
    final all = await _loadAll();
    var filtered = all;

    if (modelIds != null && modelIds.isNotEmpty) {
      filtered = filtered.where((item) => modelIds.contains(item.modelId)).toList();
    }
    if (schedulers != null && schedulers.isNotEmpty) {
      filtered = filtered.where((item) {
        final scheduler = item.params['scheduler']?.toString() ?? '';
        return schedulers.contains(scheduler);
      }).toList();
    }
    if (sizes != null && sizes.isNotEmpty) {
      filtered = filtered.where((item) {
        final size = '${item.width}x${item.height}';
        return sizes.contains(size);
      }).toList();
    }
    if (favoritesOnly) {
      filtered = filtered.where((item) => item.favorite).toList();
    }

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  /// 加载最新的 N 条记录
  static Future<List<HistoryItem>> loadRecentForModel(String modelId, int limit) async {
    final all = await _loadAll();
    final filtered = all
        .where((item) => item.modelId == modelId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.take(limit).toList();
  }

  /// 保存生成的图片到历史记录
  static Future<HistoryItem?> saveGeneratedImage({
    required String modelId,
    required String imagePath,
    required Map<String, dynamic> params,
    required String mode,
    String? upscalerId,
  }) async {
    final all = await _loadAll();
    final maxId = all.isEmpty ? 0 : all.map((e) => e.id).reduce((a, b) => a > b ? a : b);

    final width = params['width'] as int? ?? 512;
    final height = params['height'] as int? ?? 512;
    final prompt = params['prompt'] as String? ?? '';
    final negativePrompt = params['negative_prompt'] as String? ?? '';

    final item = HistoryItem(
      id: maxId + 1,
      modelId: modelId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      imagePath: imagePath,
      width: width,
      height: height,
      mode: mode,
      prompt: prompt,
      negativePrompt: negativePrompt,
      params: params,
    );

    all.insert(0, item);
    await _saveAll(all);
    return item;
  }

  /// 保存历史记录（通用）
  static Future<HistoryItem?> saveHistoryItem(HistoryItem item) async {
    final all = await _loadAll();
    all.insert(0, item);
    await _saveAll(all);
    return item;
  }

  /// 设置/取消收藏
  static Future<bool> setFavorite(int id, bool favorite) async {
    final all = await _loadAll();
    final idx = all.indexWhere((item) => item.id == id);
    if (idx < 0) return false;
    all[idx] = HistoryItem(
      id: all[idx].id,
      modelId: all[idx].modelId,
      timestamp: all[idx].timestamp,
      imagePath: all[idx].imagePath,
      width: all[idx].width,
      height: all[idx].height,
      mode: all[idx].mode,
      prompt: all[idx].prompt,
      negativePrompt: all[idx].negativePrompt,
      favorite: favorite,
      params: all[idx].params,
    );
    await _saveAll(all);
    return true;
  }

  /// 删除单条历史记录
  static Future<bool> deleteHistoryItem(HistoryItem item) async {
    final all = await _loadAll();
    final before = all.length;
    all.removeWhere((e) => e.id == item.id);
    if (all.length < before) {
      await _saveAll(all);
      return true;
    }
    return false;
  }

  /// 批量删除历史记录
  static Future<int> deleteHistoryItems(List<HistoryItem> items) async {
    final all = await _loadAll();
    final idsToRemove = items.map((e) => e.id).toSet();
    final before = all.length;
    all.removeWhere((e) => idsToRemove.contains(e.id));
    final removed = before - all.length;
    if (removed > 0) {
      await _saveAll(all);
    }
    return removed;
  }

  /// 清空某个模型的全部历史
  static Future<bool> clearHistoryForModel(String modelId) async {
    final all = await _loadAll();
    final before = all.length;
    all.removeWhere((e) => e.modelId == modelId);
    if (all.length < before) {
      await _saveAll(all);
      return true;
    }
    return false;
  }

  /// 重命名模型的历史记录
  static Future<void> renameModel(String oldId, String newId) async {
    final all = await _loadAll();
    bool changed = false;
    for (var i = 0; i < all.length; i++) {
      if (all[i].modelId == oldId) {
        all[i] = HistoryItem(
          id: all[i].id,
          modelId: newId,
          timestamp: all[i].timestamp,
          imagePath: all[i].imagePath,
          width: all[i].width,
          height: all[i].height,
          mode: all[i].mode,
          prompt: all[i].prompt,
          negativePrompt: all[i].negativePrompt,
          favorite: all[i].favorite,
          params: all[i].params,
        );
        changed = true;
      }
    }
    if (changed) {
      await _saveAll(all);
    }
  }

  /// 获取已知的模型 ID 列表
  static Future<List<String>> getKnownModelIds() async {
    final all = await _loadAll();
    return all.map((e) => e.modelId).toSet().toList();
  }

  /// 获取已知的调度器列表
  static Future<List<String>> getKnownSchedulers() async {
    final all = await _loadAll();
    return all
        .map((e) => e.params['scheduler']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  /// 获取已知的尺寸列表
  static Future<List<String>> getKnownSizes() async {
    final all = await _loadAll();
    return all
        .map((e) => '${e.width}x${e.height}')
        .toSet()
        .toList();
  }
}
