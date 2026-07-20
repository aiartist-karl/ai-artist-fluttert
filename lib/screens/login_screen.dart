import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _doAuth(AuthProvider auth) {
    final u = _usernameCtrl.text.trim();
    final p = _passwordCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) return;
    if (_tabController.index == 0) {
      auth.login(u, p);
    } else {
      auth.register(u, p).then((ok) {
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('注册成功，请登录')));
          _tabController.index = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.smart_toy, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('AI Artist', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('请登录以继续使用', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                TabBar(
                  controller: _tabController,
                  onTap: (_) => auth.clearError(),
                  tabs: const [Tab(text: '登录'), Tab(text: '注册')],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: '用户名', prefixIcon: Icon(Icons.person)),
                  onChanged: (_) => auth.clearError(),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: '密码', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  onChanged: (_) => auth.clearError(),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _doAuth(auth),
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(auth.errorMessage!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: auth.isLoading ? null : () => _doAuth(auth),
                    child: auth.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_tabController.index == 0 ? '登录' : '注册', style: theme.textTheme.titleMedium),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
