import 'package:flutter/foundation.dart';
import '../models/credits_record.dart';
import '../services/credits_service.dart';

/// 积分管理
/// 参考 Android CreditsHistoryManager.kt 的逻辑
class CreditsProvider extends ChangeNotifier {
  // ==================== 状态变量 ====================
  int _balance = 0;
  final List<CreditsRecord> _records = [];
  bool _isLoading = false;
  bool _isLoadingRecords = false;
  String? _errorMessage;

  // 最大记录数（对应 Android MAX_RECORDS = 200）
  static const int maxRecords = 200;

  // ==================== Getters ====================
  int get balance => _balance;
  List<CreditsRecord> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;
  bool get isLoadingRecords => _isLoadingRecords;
  String? get errorMessage => _errorMessage;

  /// 按类型过滤的记录
  List<CreditsRecord> get chatRecords =>
      _records.where((r) => r.type == 'chat').toList();

  List<CreditsRecord> get imageRecords =>
      _records.where((r) => r.type == 'image').toList();

  List<CreditsRecord> get rechargeRecords =>
      _records.where((r) => r.type == 'recharge').toList();

  List<CreditsRecord> get cardRedeemRecords =>
      _records.where((r) => r.type == 'card_redeem').toList();

  // ==================== 操作方法 ====================

  /// 设置本地余额（用于快速同步）
  void setBalance(int balance) {
    _balance = balance;
    notifyListeners();
  }

  /// 加载本地消费记录
  Future<void> loadRecords() async {
    _isLoadingRecords = true;
    _clearError();
    notifyListeners();

    try {
      final loadedRecords = await CreditsService.loadLocalRecords();
      _records
        ..clear()
        ..addAll(loadedRecords);
    } catch (e) {
      _errorMessage = '加载记录失败: ${e.toString()}';
    } finally {
      _isLoadingRecords = false;
      notifyListeners();
    }
  }

  /// 从服务器加载消费记录
  Future<void> loadServerTransactions({int page = 1, int size = 20}) async {
    _isLoadingRecords = true;
    _clearError();
    notifyListeners();

    try {
      final items = await CreditsService.getServerTransactions(page: page, size: size);
      if (page == 1) {
        _records.clear();
      }
      _records.addAll(items);

      // 限制记录数量
      if (_records.length > maxRecords) {
        _records.removeRange(maxRecords, _records.length);
      }
    } catch (e) {
      _errorMessage = '加载服务器记录失败: ${e.toString()}';
    } finally {
      _isLoadingRecords = false;
      notifyListeners();
    }
  }

  /// 添加本地消费记录
  Future<void> addRecord({
    required String type,
    required String description,
    required int amount,
    required int balanceAfter,
  }) async {
    final record = CreditsRecord(
      id: DateTime.now().millisecondsSinceEpoch,
      type: type,
      description: description,
      amount: amount,
      balanceAfter: balanceAfter,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    // 最新记录插在前面
    _records.insert(0, record);

    // 限制记录数量
    if (_records.length > maxRecords) {
      _records.removeRange(maxRecords, _records.length);
    }

    // 更新余额
    _balance = balanceAfter;
    notifyListeners();

    try {
      await CreditsService.saveLocalRecord(record);
    } catch (e) {
      debugPrint('保存本地记录失败: $e');
    }
  }

  /// 查询服务器积分余额
  Future<void> fetchBalance() async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final result = await CreditsService.fetchBalance();
      if (result != null) {
        _balance = result;
      }
    } catch (e) {
      _errorMessage = '查询积分失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 扣除积分
  Future<bool> deduct({
    required int amount,
    String description = '消费',
  }) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final newBalance = await CreditsService.deductCredits(
        amount: amount,
        description: description,
      );

      if (newBalance != null) {
        _balance = newBalance;
        await addRecord(
          type: 'chat',
          description: description,
          amount: -amount,
          balanceAfter: newBalance,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = '扣费失败';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '扣费失败: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 创建充值订单
  Future<String?> createRechargeOrder(String productId) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final orderId = await CreditsService.createRechargeOrder(productId);
      _isLoading = false;
      notifyListeners();
      return orderId;
    } catch (e) {
      _errorMessage = '创建订单失败: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// 卡密兑换
  Future<bool> redeemCard(String cardCode) async {
    if (cardCode.trim().isEmpty) {
      _errorMessage = '卡密不能为空';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final newBalance = await CreditsService.redeemCardCode(cardCode.trim());
      if (newBalance != null) {
        _balance = newBalance;
        await addRecord(
          type: 'card_redeem',
          description: '卡密兑换',
          amount: 0, // 具体金额由服务器决定
          balanceAfter: newBalance,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = '兑换失败';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '兑换失败: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 清除错误
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ==================== 静态工具方法 ====================

  /// 获取类型显示名称
  static String getTypeDisplayName(String type) {
    switch (type) {
      case 'chat':
        return '对话';
      case 'image':
        return '生图';
      case 'recharge':
        return '充值';
      case 'card_redeem':
        return '卡密兑换';
      default:
        return type;
    }
  }

  /// 获取类型 emoji
  static String getTypeEmoji(String type) {
    switch (type) {
      case 'chat':
        return '💬';
      case 'image':
        return '🖼️';
      case 'recharge':
        return '💰';
      case 'card_redeem':
        return '🎫';
      default:
        return '📋';
    }
  }

  /// 格式化时间
  static String formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }

  // ==================== 私有方法 ====================
  void _clearError() {
    _errorMessage = null;
  }
}
