import 'package:flutter/foundation.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';

/// 历史对话管理
/// 参考 Android HistoryManager.kt 的逻辑
class HistoryProvider extends ChangeNotifier {
  // ==================== 状态变量 ====================
  final List<HistoryItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentModelId;

  // 筛选条件
  Set<String> _filterModelIds = {};
  Set<String> _filterSchedulers = {};
  Set<String> _filterSizes = {};
  bool _filterFavoritesOnly = false;

  // 已知的筛选项（从数据库加载）
  List<String> _knownModelIds = [];
  List<String> _knownSchedulers = [];
  List<String> _knownSizes = [];

  // ==================== Getters ====================
  List<HistoryItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentModelId => _currentModelId;
  Set<String> get filterModelIds => Set.unmodifiable(_filterModelIds);
  Set<String> get filterSchedulers => Set.unmodifiable(_filterSchedulers);
  Set<String> get filterSizes => Set.unmodifiable(_filterSizes);
  bool get filterFavoritesOnly => _filterFavoritesOnly;
  List<String> get knownModelIds => List.unmodifiable(_knownModelIds);
  List<String> get knownSchedulers => List.unmodifiable(_knownSchedulers);
  List<String> get knownSizes => List.unmodifiable(_knownSizes);

  /// 收藏项数量
  int get favoriteCount => _items.where((i) => i.favorite).length;

  /// 总数
  int get totalCount => _items.length;

  // ==================== 操作方法 ====================

  /// 加载指定模型的历史记录
  Future<void> loadHistoryForModel(String modelId) async {
    _isLoading = true;
    _currentModelId = modelId;
    _clearError();
    notifyListeners();

    try {
      final loadedItems = await HistoryService.loadHistoryForModel(modelId);
      _items
        ..clear()
        ..addAll(loadedItems);
    } catch (e) {
      _errorMessage = '加载历史记录失败: ${e.toString()}';
      _items.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载全部历史记录（支持筛选）
  Future<void> loadAll({
    Set<String>? modelIds,
    Set<String>? schedulers,
    Set<String>? sizes,
    bool favoritesOnly = false,
  }) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final loadedItems = await HistoryService.queryHistory(
        modelIds: modelIds ?? _filterModelIds,
        schedulers: schedulers ?? _filterSchedulers,
        sizes: sizes ?? _filterSizes,
        favoritesOnly: favoritesOnly || _filterFavoritesOnly,
      );
      _items
        ..clear()
        ..addAll(loadedItems);
    } catch (e) {
      _errorMessage = '加载历史记录失败: ${e.toString()}';
      _items.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载最新的 N 条记录
  Future<void> loadRecent(String modelId, {int limit = 20}) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final recentItems = await HistoryService.loadRecentForModel(modelId, limit);
      _items
        ..clear()
        ..addAll(recentItems);
    } catch (e) {
      _errorMessage = '加载最近记录失败: ${e.toString()}';
      _items.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 保存生成的图片到历史
  Future<HistoryItem?> saveGeneratedImage({
    required String modelId,
    required String imagePath,
    required Map<String, dynamic> params,
    required String mode,
    String? upscalerId,
  }) async {
    try {
      final item = await HistoryService.saveGeneratedImage(
        modelId: modelId,
        imagePath: imagePath,
        params: params,
        mode: mode,
        upscalerId: upscalerId,
      );

      if (item != null) {
        _items.insert(0, item);
        notifyListeners();
      }
      return item;
    } catch (e) {
      _errorMessage = '保存历史记录失败: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// 设置/取消收藏
  Future<void> setFavorite(int id, bool favorite) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;

    final oldFavorite = _items[idx].favorite;
    _items[idx] = _items[idx].copyWith(favorite: favorite);
    notifyListeners();

    try {
      final success = await HistoryService.setFavorite(id, favorite);
      if (!success) {
        _items[idx] = _items[idx].copyWith(favorite: oldFavorite);
        notifyListeners();
      }
    } catch (e) {
      _items[idx] = _items[idx].copyWith(favorite: oldFavorite);
      _errorMessage = '更新收藏失败: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 删除单条记录
  Future<void> deleteItem(HistoryItem item) async {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx < 0) return;

    final removed = _items.removeAt(idx);
    notifyListeners();

    try {
      final success = await HistoryService.deleteHistoryItem(removed);
      if (!success) {
        _items.insert(idx, removed);
        notifyListeners();
      }
    } catch (e) {
      _items.insert(idx, removed);
      _errorMessage = '删除失败: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 批量删除
  Future<int> deleteItems(List<HistoryItem> itemsToDelete) async {
    if (itemsToDelete.isEmpty) return 0;

    final removedItems = <int, HistoryItem>{};
    for (final item in itemsToDelete) {
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx >= 0) {
        removedItems[idx] = _items.removeAt(idx);
      }
    }
    notifyListeners();

    try {
      final count = await HistoryService.deleteHistoryItems(itemsToDelete);
      return count;
    } catch (e) {
      // 回滚
      for (final entry in removedItems.entries) {
        _items.insert(entry.key, entry.value);
      }
      _errorMessage = '批量删除失败: ${e.toString()}';
      notifyListeners();
      return 0;
    }
  }

  /// 清空某个模型的全部历史
  Future<void> clearHistoryForModel(String modelId) async {
    final previousItems = List<HistoryItem>.from(_items);
    _items.clear();
    notifyListeners();

    try {
      final success = await HistoryService.clearHistoryForModel(modelId);
      if (!success) {
        _items.addAll(previousItems);
        notifyListeners();
      }
    } catch (e) {
      _items.addAll(previousItems);
      _errorMessage = '清空历史失败: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 重命名模型的历史记录（迁移到新模型ID）
  Future<void> renameModel(String oldId, String newId) async {
    try {
      await HistoryService.renameModel(oldId, newId);
      // 刷新列表
      if (_currentModelId == oldId) {
        await loadHistoryForModel(newId);
      }
    } catch (e) {
      _errorMessage = '重命名失败: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 加载已知的筛选项
  Future<void> loadFilterOptions() async {
    try {
      _knownModelIds = await HistoryService.getKnownModelIds();
      _knownSchedulers = await HistoryService.getKnownSchedulers();
      _knownSizes = await HistoryService.getKnownSizes();
      notifyListeners();
    } catch (e) {
      debugPrint('加载筛选项失败: $e');
    }
  }

  // ==================== 筛选操作 ====================

  void setFilterModelIds(Set<String> modelIds) {
    _filterModelIds = Set.from(modelIds);
    notifyListeners();
  }

  void setFilterSchedulers(Set<String> schedulers) {
    _filterSchedulers = Set.from(schedulers);
    notifyListeners();
  }

  void setFilterSizes(Set<String> sizes) {
    _filterSizes = Set.from(sizes);
    notifyListeners();
  }

  void setFilterFavoritesOnly(bool value) {
    _filterFavoritesOnly = value;
    notifyListeners();
  }

  void resetFilters() {
    _filterModelIds = {};
    _filterSchedulers = {};
    _filterSizes = {};
    _filterFavoritesOnly = false;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ==================== 私有方法 ====================
  void _clearError() {
    _errorMessage = null;
  }
}
