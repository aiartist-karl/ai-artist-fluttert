import '../models/history_item.dart';

/// 历史记录服务
class HistoryService {
  static Future<List<HistoryItem>> loadHistory({String? modelId, bool? favoriteOnly}) async {
    // Placeholder
    return [];
  }

  static Future<HistoryItem?> saveHistoryItem(HistoryItem item) async {
    return item;
  }

  static Future<bool> setFavorite(int id, bool favorite) async {
    return true;
  }

  static Future<bool> deleteHistoryItem(HistoryItem item) async {
    return true;
  }

  static Future<int> deleteHistoryItems(List<HistoryItem> items) async {
    return items.length;
  }

  static Future<List<String>> getKnownModelIds() async => [];
  static Future<List<String>> getKnownSchedulers() async => [];
  static Future<List<String>> getKnownSizes() async => [];
}
