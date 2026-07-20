import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/credits_record.dart';
import '../utils/constants.dart';

/// 积分服务
/// 对应 Android CreditsHistoryManager.kt + UserManager.kt 的积分逻辑
class CreditsService {
  static const String _keyRecords = 'credits_records';
  static const String _keyBalance = 'credits_balance_local';

  static Future<List<CreditsRecord>> loadLocalRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyRecords);
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => CreditsRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveLocalRecord(CreditsRecord record) async {
    final records = await loadLocalRecords();
    records.insert(0, record);
    // Keep max 200 records
    if (records.length > 200) records.removeRange(200, records.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRecords, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  static Future<int> fetchBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBalance) ?? 0;
  }

  static Future<void> setBalanceLocal(int balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBalance, balance);
  }

  static Future<int> deductCredits(int amount, {String description = '消费'}) async {
    final balance = await fetchBalance();
    if (balance < amount) return balance;
    final newBalance = balance - amount;
    await setBalanceLocal(newBalance);
    return newBalance;
  }

  static Future<String> createRechargeOrder(String productId) async {
    // Placeholder - in real app, call server API
    return 'order_placeholder';
  }

  static Future<int> redeemCardCode(String cardCode) async {
    // Placeholder - in real app, call server API
    final balance = await fetchBalance();
    return balance;
  }

  static Future<List<Map<String, dynamic>>> getServerTransactions({int page = 1, int size = 20}) async {
    // Placeholder - in real app, call server API
    return [];
  }
}
