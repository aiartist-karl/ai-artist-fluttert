import 'dart:convert';

/// 用户认证结果
/// 对应 Android: UserManager.AuthResult
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  final String userId;
  final String username;
  final String token;
  final int credits;

  const AuthSuccess({
    required this.userId,
    required this.username,
    required this.token,
    required this.credits,
  });

  @override
  String toString() => 'AuthSuccess(userId: $userId, username: $username, credits: $credits)';
}

class AuthError extends AuthResult {
  final String message;

  const AuthError(this.message);

  @override
  String toString() => 'AuthError($message)';
}

/// 积分信息
/// 对应 Android: UserManager.CreditsInfo
class CreditsInfo {
  final int balance;

  const CreditsInfo(this.balance);

  factory CreditsInfo.fromJson(Map<String, dynamic> json) {
    return CreditsInfo(json['balance'] as int? ?? json['credits'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() => {'balance': balance};

  @override
  String toString() => 'CreditsInfo(balance: $balance)';
}

/// 消费记录
/// 对应 Android: UserManager.getTransactions() 中的 map
class TransactionRecord {
  final int amount;
  final String type;
  final String description;
  final int balanceAfter;
  final String createdAt;

  const TransactionRecord({
    this.amount = 0,
    this.type = '',
    this.description = '',
    this.balanceAfter = 0,
    this.createdAt = '',
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      amount: json['amount'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      balanceAfter: json['balance_after'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'type': type,
        'description': description,
        'balance_after': balanceAfter,
        'created_at': createdAt,
      };
}

/// 用户状态管理模型（本地持久化部分）
/// 对应 Android: UserManager 中的 SharedPreferences 持久化字段
class UserSession {
  final String token;
  final String username;
  final String userId;
  final int creditsBalance;

  const UserSession({
    this.token = '',
    this.username = '',
    this.userId = '',
    this.creditsBalance = 0,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      token: json['token'] as String? ?? '',
      username: json['username'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      creditsBalance: json['credits_balance'] as int? ?? json['credits'] as int? ?? 0,
    );
  }

  factory UserSession.fromJsonString(String jsonString) {
    return UserSession.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'username': username,
        'user_id': userId,
        'credits_balance': creditsBalance,
      };

  String toJsonString() => jsonEncode(toJson());

  bool get isLoggedIn => token.isNotEmpty;

  UserSession copyWith({
    String? token,
    String? username,
    String? userId,
    int? creditsBalance,
  }) {
    return UserSession(
      token: token ?? this.token,
      username: username ?? this.username,
      userId: userId ?? this.userId,
      creditsBalance: creditsBalance ?? this.creditsBalance,
    );
  }

  @override
  String toString() =>
      'UserSession(userId: $userId, username: $username, credits: $creditsBalance, loggedIn: $isLoggedIn)';
}
