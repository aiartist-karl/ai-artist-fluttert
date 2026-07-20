import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户认证服务
/// 后端地址 http://47.116.29.140，路由前缀 /auth/auth/
/// URL 映射: APP /auth/xxx → Nginx proxy /auth/ → /api/ on FastAPI :5001
class AuthService {
  static const String baseUrl = 'http://47.116.29.140';
  static const String apiPrefix = '/auth/auth';

  static const String _prefsKey = 'user_auth_prefs';
  static const String _keyToken = 'auth_token';
  static const String _keyUsername = 'auth_username';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyCredits = 'credits_balance';

  final Dio _dio;
  SharedPreferences? _prefs;

  AuthService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── 状态查询 ───

  bool get isLoggedIn {
    final token = _prefs?.getString(_keyToken);
    return token != null && token.isNotEmpty;
  }

  String? get token => _prefs?.getString(_keyToken);
  String? get username => _prefs?.getString(_keyUsername);
  String get userId => _prefs?.getString(_keyUserId) ?? '';
  int get creditsBalance => _prefs?.getInt(_keyCredits) ?? 0;

  void setCreditsLocal(int balance) {
    _prefs?.setInt(_keyCredits, balance);
  }

  void logout() {
    _prefs?.remove(_keyToken);
    _prefs?.remove(_keyUsername);
    _prefs?.remove(_keyUserId);
    _prefs?.remove(_keyCredits);
  }

  // ─── 请求头 ───

  Map<String, dynamic> get _authHeaders {
    final t = token;
    if (t == null || t.isEmpty) return {};
    return {'Authorization': 'Bearer $t'};
  }

  // ─── 登录 / 注册 ───

  Future<AuthResult> login(String username, String password) async {
    return _callAuth('login', username, password);
  }

  Future<AuthResult> register(String username, String password) async {
    return _callAuth('register', username, password);
  }

  Future<AuthResult> _callAuth(
    String endpoint,
    String username,
    String password,
  ) async {
    try {
      if (username.trim().isEmpty || password.trim().isEmpty) {
        return AuthResult.error('用户名和密码不能为空');
      }

      final url = '$baseUrl$apiPrefix/$endpoint';
      final resp = await _dio.post(
        url,
        data: {'username': username, 'password': password},
      );

      final data = resp.data;
      if (data is! Map<String, dynamic>) {
        return AuthResult.error('响应数据格式错误');
      }

      final code = data['code'] as int? ?? -1;
      if (code != 0) {
        return AuthResult.error(data['msg'] as String? ?? '未知错误');
      }

      final innerData = data['data'] as Map<String, dynamic>?;
      if (innerData == null) {
        return AuthResult.error('响应数据格式错误');
      }

      final userId = innerData['user_id'] as String? ?? '';
      final returnedUsername =
          innerData['username'] as String? ?? username;
      final tok = innerData['token'] as String? ?? '';
      final credits = innerData['credits'] as int? ?? 0;

      if (tok.isEmpty) {
        return AuthResult.error('未获取到 token');
      }

      final p = _prefs;
      if (p != null) {
        await p
          ..setString(_keyToken, tok)
          ..setString(_keyUsername, returnedUsername)
          ..setString(_keyUserId, userId)
          ..setInt(_keyCredits, credits);
      }

      return AuthResult.success(
        userId: userId,
        username: returnedUsername,
        token: tok,
        credits: credits,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        return AuthResult.error('服务器连接失败 (HTTP ${e.response!.statusCode})');
      }
      return AuthResult.error('网络请求失败: ${e.message ?? "请检查网络连接"}');
    } catch (e) {
      return AuthResult.error('网络请求失败: $e');
    }
  }

  // ─── 积分查询 ───

  Future<CreditsResult<CreditsInfo>> getCredits() async {
    try {
      final t = token;
      if (t == null) return CreditsResult.error('未登录，请先登录');

      final resp = await _dio.get(
        '$baseUrl$apiPrefix/credits',
        options: Options(headers: _authHeaders),
      );

      final data = resp.data as Map<String, dynamic>;
      final code = data['code'] as int? ?? -1;
      if (code != 0) {
        return CreditsResult.error(data['msg'] as String? ?? '查询积分失败');
      }

      final innerData = data['data'] as Map<String, dynamic>?;
      if (innerData == null) {
        return CreditsResult.error('响应数据格式错误');
      }

      final balance = innerData['credits'] as int? ?? 0;
      setCreditsLocal(balance);
      return CreditsResult.success(CreditsInfo(balance: balance));
    } on DioException catch (e) {
      return CreditsResult.error(
          '查询积分失败: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      return CreditsResult.error('查询积分失败: $e');
    }
  }

  // ─── 创建充值订单 ───

  Future<CreditsResult<String>> createRechargeOrder(String productId) async {
    try {
      final t = token;
      if (t == null) return CreditsResult.error('未登录，请先登录');

      final resp = await _dio.post(
        '$baseUrl$apiPrefix/orders',
        data: {'product_id': productId},
        options: Options(headers: _authHeaders),
      );

      final data = resp.data as Map<String, dynamic>;
      final code = data['code'] as int? ?? -1;
      if (code != 0) {
        return CreditsResult.error(data['msg'] as String? ?? '创建订单失败');
      }

      final innerData = data['data'] as Map<String, dynamic>?;
      if (innerData == null) {
        return CreditsResult.error('响应数据格式错误');
      }

      final orderId = innerData['order_id'] as String? ?? '';
      if (orderId.isEmpty) {
        return CreditsResult.error('未获取到订单号');
      }
      return CreditsResult.success(orderId);
    } on DioException catch (e) {
      return CreditsResult.error(
          '创建订单失败: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      return CreditsResult.error('创建订单失败: $e');
    }
  }

  // ─── 扣除积分 ───

  Future<CreditsResult<CreditsInfo>> deductCredits(
    int amount, {
    String description = '消费',
  }) async {
    try {
      final t = token;
      if (t == null) return CreditsResult.error('未登录，请先登录');

      final resp = await _dio.post(
        '$baseUrl$apiPrefix/deduct',
        data: {
          'amount': amount,
          'description': description,
          'type': 'consume',
        },
        options: Options(headers: _authHeaders),
      );

      final data = resp.data as Map<String, dynamic>;
      final code = data['code'] as int? ?? -1;
      if (code != 0) {
        return CreditsResult.error(data['msg'] as String? ?? '扣费失败');
      }

      final innerData = data['data'] as Map<String, dynamic>?;
      if (innerData == null) {
        return CreditsResult.error('响应数据格式错误');
      }

      final balance = innerData['credits_remaining'] as int? ?? 0;
      setCreditsLocal(balance);
      return CreditsResult.success(CreditsInfo(balance: balance));
    } on DioException catch (e) {
      return CreditsResult.error(
          '扣费失败: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      return CreditsResult.error('扣费失败: $e');
    }
  }

  // ─── 卡密兑换 ───

  Future<CreditsResult<CreditsInfo>> redeemCardCode(String cardCode) async {
    try {
      final t = token;
      if (t == null) return CreditsResult.error('未登录，请先登录');
      if (cardCode.trim().isEmpty) {
        return CreditsResult.error('卡密不能为空');
      }

      final resp = await _dio.post(
        '$baseUrl$apiPrefix/cards/redeem',
        data: {'card_code': cardCode.trim()},
        options: Options(headers: _authHeaders),
      );

      final data = resp.data as Map<String, dynamic>;
      final code = data['code'] as int? ?? -1;
      if (code != 0) {
        return CreditsResult.error(data['msg'] as String? ?? '兑换失败');
      }

      final innerData = data['data'] as Map<String, dynamic>?;
      if (innerData == null) {
        return CreditsResult.error('响应数据格式错误');
      }

      final balance = innerData['credits_remaining'] as int? ?? 0;
      setCreditsLocal(balance);
      return CreditsResult.success(CreditsInfo(balance: balance));
    } on DioException catch (e) {
      return CreditsResult.error(
          '兑换失败: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      return CreditsResult.error('兑换失败: $e');
    }
  }

  // ─── 消费记录 ───

  Future<CreditsResult<List<Map<String, dynamic>>>> getTransactions({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final t = token;
      if (t == null) return CreditsResult.error('未登录，请先登录');

      final resp = await _dio.get(
        '$baseUrl$apiPrefix/transactions',
        queryParameters: {'page': page, 'size': size},
        options: Options(headers: _authHeaders),
      );

      final data = resp.data as Map<String, dynamic>;
      final code = data['code'] as int? ?? -1;
      if (code != 0) {
        return CreditsResult.error(data['msg'] as String? ?? '查询记录失败');
      }

      final innerData = data['data'] as Map<String, dynamic>?;
      if (innerData == null) {
        return CreditsResult.error('响应数据格式错误');
      }

      final items = innerData['items'] as List<dynamic>? ?? [];
      final result = items.map((item) {
        final m = item as Map<String, dynamic>;
        return {
          'amount': m['amount'] as int? ?? 0,
          'type': m['type'] as String? ?? '',
          'description': m['description'] as String? ?? '',
          'balance_after': m['balance_after'] as int? ?? 0,
          'created_at': m['created_at'] as String? ?? '',
        };
      }).toList();

      return CreditsResult.success(result);
    } on DioException catch (e) {
      return CreditsResult.error(
          '查询记录失败: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      return CreditsResult.error('查询记录失败: $e');
    }
  }

  void dispose() {
    _dio.close();
  }
}

// ─── 数据模型 ───

class AuthResult {
  final bool isSuccess;
  final String? userId;
  final String? username;
  final String? token;
  final int? credits;
  final String? errorMessage;

  AuthResult._({
    required this.isSuccess,
    this.userId,
    this.username,
    this.token,
    this.credits,
    this.errorMessage,
  });

  factory AuthResult.success({
    required String userId,
    required String username,
    required String token,
    required int credits,
  }) =>
      AuthResult._(
        isSuccess: true,
        userId: userId,
        username: username,
        token: token,
        credits: credits,
      );

  factory AuthResult.error(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}

class CreditsInfo {
  final int balance;
  CreditsInfo({required this.balance});
}

class CreditsResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  CreditsResult._({required this.isSuccess, this.data, this.errorMessage});

  factory CreditsResult.success(T data) =>
      CreditsResult._(isSuccess: true, data: data);

  factory CreditsResult.error(String message) =>
      CreditsResult._(isSuccess: false, errorMessage: message);
}
