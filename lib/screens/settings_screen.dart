import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'agent_management_screen.dart';
import 'api_settings_screen.dart';
import 'charge_screen.dart';
import 'credits_history_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: ListTile(
              leading: Icon(Icons.monetization_on, size: 32, color: theme.colorScheme.onTertiaryContainer),
              title: Text('我的积分', style: TextStyle(color: theme.colorScheme.onTertiaryContainer)),
              subtitle: Text('当前余额: ${auth.creditsBalance} 积分', style: TextStyle(color: theme.colorScheme.onTertiaryContainer)),
              trailing: Text('充值', style: TextStyle(color: theme.colorScheme.onTertiaryContainer, fontWeight: FontWeight.w500)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChargeScreen())),
            ),
          ),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const Icon(Icons.smart_toy, size: 32),
            title: const Text('智能体管理'),
            subtitle: Text('管理你的AI助手', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentManagementScreen())),
          )),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const Text('📋', style: TextStyle(fontSize: 24)),
            title: const Text('消费记录'),
            subtitle: Text('查看积分充值和消费明细', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditsHistoryScreen())),
          )),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const Icon(Icons.cloud, size: 32),
            title: const Text('API 设置'),
            subtitle: Text('配置AI服务和模型', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiSettingsScreen())),
          )),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('记忆注入数量', style: theme.textTheme.titleMedium),
                Text('对话时自动注入的相关记忆条数（1-20）', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Slider(value: settings.memoryContextCount.toDouble(), min: 1, max: 20, divisions: 19, label: '${settings.memoryContextCount}', onChanged: (v) => settings.setMemoryContextCount(v.toInt()))),
                  SizedBox(width: 32, child: Text('${settings.memoryContextCount}', style: theme.textTheme.titleMedium, textAlign: TextAlign.center)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('主题', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'system', label: Text('系统')),
                    ButtonSegment(value: 'light', label: Text('浅色')),
                    ButtonSegment(value: 'dark', label: Text('深色')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (v) => settings.setThemeMode(v.first),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          if (auth.isLoggedIn)
            OutlinedButton.icon(onPressed: () => auth.logout(), icon: const Icon(Icons.logout), label: const Text('退出登录')),
          const SizedBox(height: 16),
          Center(child: Text('AI Artist v5.10.0', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        ],
      ),
    );
  }
}
