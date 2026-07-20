import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// 认证状态管理
class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _username;
  String _userId = '';
  int _creditsBalance = 0;
  bool _isLoading = false;
  String? _errorMessage;
  
  final AuthService _authService = AuthService();
  bool _initialized = false;

  // Getters
  String? get token => _token;
  String? get username => _username;
  String get userId => _userId;
  int get creditsBalance => _creditsBalance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> _ensureInit() async {
    if (!_initialized) {
      await _authService.init();
      _initialized = true;
    }
  }

  void _syncFromService() {
    _token = _authService.token;
    _username = _authService.username;
    _userId = _authService.userId;
    _creditsBalance = _authService.creditsBalance;
  }

  /// 登录
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _ensureInit();
      final result = await _authService.login(username, password);
      if (result.isSuccess) {
        _syncFromService();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage ?? '登录失败';
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
      await _ensureInit();
      final result = await _authService.register(username, password);
      if (result.isSuccess) {
        _syncFromService();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage ?? '注册失败';
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
    _authService.logout();
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
      await _ensureInit();
      final result = await _authService.getCredits();
      if (result.isSuccess && result.data != null) {
        _creditsBalance = result.data!.balance;
        notifyListeners();
      } else {
        _errorMessage = result.errorMessage ?? '查询积分失败';
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
      await _ensureInit();
      final result = await _authService.createRechargeOrder(productId);
      if (result.isSuccess && result.data != null) {
        return result.data;
      } else {
        _errorMessage = result.errorMessage ?? '创建订单失败';
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
      await _ensureInit();
      final result = await _authService.deductCredits(amount, description: description);
      if (result.isSuccess) {
        _syncFromService();
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage ?? '扣费失败';
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
      await _ensureInit();
      final result = await _authService.redeemCardCode(cardCode.trim());
      if (result.isSuccess) {
        _syncFromService();
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage ?? '兑换失败';
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
      await _ensureInit();
      final result = await _authService.getTransactions(page: page, size: size);
      if (result.isSuccess && result.data != null) {
        return result.data!;
      } else {
        _errorMessage = result.errorMessage ?? '查询记录失败';
        notifyListeners();
        return [];
      }
    } catch (e) {
      _errorMessage = '查询记录失败: ${e.toString()}';
      return [];
    }
  }

  void setCreditsLocal(int balance) {
    _authService.setCreditsLocal(balance);
    _creditsBalance = balance;
    notifyListeners();
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
