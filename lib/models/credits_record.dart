/// 积分消费记录
/// 对应 Android CreditsHistoryManager.kt - CreditsRecord
class CreditsRecord {
  final int id;
  final String type; // chat, image, card_redeem, register_bonus, recharge
  final String description;
  final int amount;
  final int balanceAfter;
  final int timestamp;

  CreditsRecord({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.balanceAfter,
    required this.timestamp,
  });

  factory CreditsRecord.fromJson(Map<String, dynamic> json) => CreditsRecord(
    id: json['id'] as int? ?? 0,
    type: json['type'] as String? ?? '',
    description: json['description'] as String? ?? '',
    amount: json['amount'] as int? ?? 0,
    balanceAfter: json['balanceAfter'] as int? ?? 0,
    timestamp: json['timestamp'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'description': description,
    'amount': amount,
    'balanceAfter': balanceAfter,
    'timestamp': timestamp,
  };
}

/// 充值选项
class RechargeOption {
  final int amount;
  final int baseCredits;
  final int bonus;
  final int total;

  const RechargeOption({
    required this.amount,
    required this.baseCredits,
    required this.bonus,
    required this.total,
  });
}
