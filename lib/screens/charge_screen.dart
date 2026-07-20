import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/credits_provider.dart';
import '../models/credits_record.dart';
import 'credits_history_screen.dart';

class ChargeScreen extends StatefulWidget {
  const ChargeScreen({super.key});
  @override
  State<ChargeScreen> createState() => _ChargeScreenState();
}

class _ChargeScreenState extends State<ChargeScreen> {
  static const _options = [
    RechargeOption(amount: 10, baseCredits: 1000, bonus: 100, total: 1100),
    RechargeOption(amount: 50, baseCredits: 5000, bonus: 500, total: 5500),
    RechargeOption(amount: 100, baseCredits: 10000, bonus: 1500, total: 11500),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CreditsProvider>(context, listen: false).fetchBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final credits = Provider.of<CreditsProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('积分充值'), backgroundColor: theme.colorScheme.primaryContainer, foregroundColor: theme.colorScheme.onPrimaryContainer),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: theme.colorScheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          Icon(Icons.monetization_on, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text('当前积分', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
          const SizedBox(height: 4),
          if (credits.isLoading) const CircularProgressIndicator(strokeWidth: 2)
          else Text('${credits.balance}', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
        ]))),
        const SizedBox(height: 12),
        TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditsHistoryScreen())), icon: const Text('📋'), label: const Text('查看消费记录')),
        const SizedBox(height: 12),
        Text('选择充值档位', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._options.map((opt) => Card(margin: const EdgeInsets.only(bottom: 8), color: theme.colorScheme.surfaceVariant, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('¥${opt.amount}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
            Text('${opt.baseCredits} 积分', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ])),
          if (opt.bonus > 0) Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: theme.colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(8)),
            child: Text('赠送 ${opt.bonus}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onTertiaryContainer))),
          FilledButton(onPressed: () => _showRedeem(credits, opt), child: const Text('兑换')),
        ])))),
        const SizedBox(height: 16),
        Center(child: Text('充值说明：对话消耗1积分/次，生图消耗6积分/张，积分永久有效', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center)),
      ]),
    );
  }

  void _showRedeem(CreditsProvider credits, RechargeOption option) {
    final codeCtrl = TextEditingController();
    String? error;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setS) => AlertDialog(
      title: Text('卡密兑换 - ¥${option.amount}档'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('获得积分：${option.total}（含赠送${option.bonus}）'),
        const SizedBox(height: 12),
        TextField(controller: codeCtrl, decoration: InputDecoration(labelText: '请输入卡密', hintText: 'XXXX-XXXX-XXXX-XXXX', errorText: error)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () {
          if (codeCtrl.text.trim().isEmpty) { setS(() => error = '请输入卡密'); return; }
          setS(() => error = null);
          credits.redeemCard(codeCtrl.text.trim()).then((ok) {
            if (ok) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('兑换成功！获得 ${option.total} 积分')));
              Provider.of<AuthProvider>(context, listen: false).fetchCredits();
            } else {
              setS(() => error = '兑换失败，请检查卡密');
            }
          });
        }, child: const Text('确认兑换')),
      ],
    )));
  }
}
