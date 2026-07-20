import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/credits_provider.dart';
import '../models/credits_record.dart';

class CreditsHistoryScreen extends StatelessWidget {
  const CreditsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final credits = Provider.of<CreditsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('消费记录'), backgroundColor: theme.colorScheme.primaryContainer, foregroundColor: theme.colorScheme.onPrimaryContainer),
      body: Column(children: [
        Card(margin: const EdgeInsets.all(16), color: theme.colorScheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Text('当前余额', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
          const Spacer(),
          Text('${auth.creditsBalance} 积分', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
        ]))),
        if (credits.records.isEmpty)
          Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('暂无消费记录', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('充值或消费后将在此显示记录', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          ])))
        else
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), itemCount: credits.records.length,
            itemBuilder: (context, index) {
              final r = credits.records[index];
              return Card(margin: const EdgeInsets.only(bottom: 4), color: theme.colorScheme.surfaceVariant.withOpacity(0.5), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                Text(_getTypeEmoji(r.type), style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_getTypeName(r.type), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                  Text(r.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1),
                  Text(_formatTime(r.timestamp), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${r.amount > 0 ? '+' : ''}${r.amount}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: r.amount > 0 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F))),
                  Text('余额 ${r.balanceAfter}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6))),
                ]),
              ])));
            },
          )),
      ]),
    );
  }

  static String _getTypeEmoji(String t) {
    switch (t) { case 'chat': return '💬'; case 'image': return '🎨'; case 'card_redeem': return '🎫'; case 'register_bonus': return '🎁'; default: return '📌'; }
  }
  static String _getTypeName(String t) {
    switch (t) { case 'chat': return 'AI对话'; case 'image': return 'AI生图'; case 'card_redeem': return '卡密兑换'; case 'register_bonus': return '注册奖励'; default: return '其他'; }
  }
  static String _formatTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }
}
