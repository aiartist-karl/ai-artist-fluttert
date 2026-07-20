import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/agent_provider.dart';
import 'providers/history_provider.dart';
import 'providers/credits_provider.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AgentProvider()..loadAgents()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => CreditsProvider()..fetchBalance()),
      ],
      child: const AiArtistApp(),
    ),
  );
}

class AiArtistApp extends StatelessWidget {
  const AiArtistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        ThemeMode themeMode;
        switch (settings.themeMode) {
          case 'light':
            themeMode = ThemeMode.light;
            break;
          case 'dark':
            themeMode = ThemeMode.dark;
            break;
          default:
            themeMode = ThemeMode.system;
        }
        return MaterialApp(
          title: 'AI Artist',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return auth.isLoggedIn ? const ChatScreen() : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
