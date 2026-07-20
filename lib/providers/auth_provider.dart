import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// 认证状态管理
/// 参考 Android UserManager.kt 的逻辑
class AuthProvider extends ChangeNotifier {
  // ==================== 状态变量 ====================
  String? _token;
  String? _username;
  String _userId = '';
  int _creditsBalance = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== Getters ====================
  String? get token => _token;
  String? get username => _username;
  String get userId => _userId;
  int get creditsBalance => _creditsBalance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ==================== 操作方法 ====================

  /// 登录
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.login(username, password);

      if (result['success'] == true) {
        _token = result['token'] as String?;
        _username = result['username'] as String? ?? username;
        _userId = result['userId'] as String? ?? '';
        _creditsBalance = result['credits'] as int? ?? 0;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? '登录失败';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '网络请求失败: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// 注册
  Future<bool> register(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.register(username, password);

      if (result['success'] == true) {
        _token = result['token'] as String?;
        _username = result['username'] as String? ?? username;
        _userId = result['userId'] as String? ?? '';
        _creditsBalance = result['credits'] as int? ?? 0;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? '注册失败';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '网络请求失败: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// 登出
  void logout() {
    _token = null;
    _username = null;
    _userId = '';
    _creditsBalance = 0;
    _clearError();
    notifyListeners();
  }

  /// 查询积分余额
  Future<void> fetchCredits() async {
    if (!isLoggedIn) return;

    try {
      final result = await AuthService.getCredits(_token!);
      if (result['success'] == true) {
        _creditsBalance = result['balance'] as int? ?? 0;
        notifyListeners();
      } else {
        _errorMessage = result['message'] as String? ?? '查询积分失败';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '查询积分失败: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 创建充值订单
  Future<String?> createRechargeOrder(String productId) async {
    if (!isLoggedIn) {
      _errorMessage = '未登录，请先登录';
      notifyListeners();
      return null;
    }

    try {
      final result = await AuthService.createRechargeOrder(_token!, productId);
      if (result['success'] == true) {
        return result['orderId'] as String?;
      } else {
        _errorMessage = result['message'] as String? ?? '创建订单失败';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = '创建订单失败: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// 扣除积分
  Future<bool> deductCredits(int amount, {String description = '消费'}) async {
    if (!isLoggedIn) return false;

    try {
      final result = await AuthService.deductCredits(
        _token!,
        amount,
        description,
      );
      if (result['success'] == true) {
        _creditsBalance = result['balance'] as int? ?? _creditsBalance;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? '扣费失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '扣费失败: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// 卡密兑换
  Future<bool> redeemCardCode(String cardCode) async {
    if (!isLoggedIn) {
      _errorMessage = '未登录，请先登录';
      notifyListeners();
      return false;
    }

    if (cardCode.trim().isEmpty) {
      _errorMessage = '卡密不能为空';
      notifyListeners();
      return false;
    }

    try {
      final result = await AuthService.redeemCardCode(_token!, cardCode.trim());
      if (result['success'] == true) {
        _creditsBalance = result['balance'] as int? ?? _creditsBalance;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? '兑换失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '兑换失败: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// 查询消费记录
  Future<List<Map<String, dynamic>>> getTransactions({
    int page = 1,
    int size = 20,
  }) async {
    if (!isLoggedIn) return [];

    try {
      final result = await AuthService.getTransactions(_token!, page, size);
      if (result['success'] == true) {
        return (result['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } else {
        _errorMessage = result['message'] as String? ?? '查询记录失败';
        notifyListeners();
        return [];
      }
    } catch (e) {
      _errorMessage = '查询记录失败: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  /// 更新本地积分余额
  void setCreditsLocal(int balance) {
    _creditsBalance = balance;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ==================== 私有方法 ====================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
