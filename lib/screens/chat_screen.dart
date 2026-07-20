import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/agent_provider.dart';
import '../providers/settings_provider.dart';
import '../models/chat_message.dart';
import '../models/agent_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/agent_switcher.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  QuotedMessage? _quotedMessage;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final input = chat.inputText.trim();
    if (input.isEmpty) return;

    // Check credits
    if (auth.isLoggedIn && auth.creditsBalance <= 0) {
      _showNoCreditsDialog();
      return;
    }

    final quoted = _quotedMessage;
    final finalContent = quoted != null
        ? '[回复: ${quoted.content.length > 30 ? quoted.content.substring(0, 30) : quoted.content}]\n\n$input'
        : input;

    _quotedMessage = null;
    chat.setInputText(finalContent);
    chat.sendMessage().then((_) {
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  void _showNoCreditsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('积分不足'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('当前积分余额为 0，无法发送消息。'),
            const SizedBox(height: 8),
            Text('请前往「设置 → 我的积分」进行充值后继续对话。',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            child: const Text('去充值'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final agentProv = Provider.of<AgentProvider>(context);
    final theme = Theme.of(context);

    _scrollToBottom();

    final activeAgent = agentProv.activeAgent;
    final displayName = activeAgent.name;
    final displayEmoji = activeAgent.emoji;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme, displayName, displayEmoji, agentProv),
            // Credits bar
            if (auth.isLoggedIn) _buildCreditsBar(auth),
            // Messages
            Expanded(
              child: chat.messages.isEmpty
                  ? _buildWelcome(theme, displayName)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chat.messages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ChatBubble(
                            message: msg,
                            onSpeak: msg.role == 'assistant' && !msg.isLoading ? () {} : null,
                            onStopSpeak: () {},
                            onCopy: () {},
                            onQuote: msg.role == 'user'
                                ? () {
                                    _quotedMessage = QuotedMessage(
                                      messageId: msg.timestamp.toString(),
                                      content: msg.content.length > 100 ? msg.content.substring(0, 100) : msg.content,
                                      isUser: true,
                                    );
                                    _inputFocus.requestFocus();
                                    setState(() {});
                                  }
                                : null,
                            onImageTap: msg.imageUrl != null ? () {} : null,
                          ),
                        );
                      },
                    ),
            ),
            // Tool progress
            if (chat.toolProgress.isNotEmpty && chat.isLoading) _buildToolProgress(chat),
            // Input
            MessageInput(
              focusNode: _inputFocus,
              inputText: chat.inputText,
              onInputChange: (v) => chat.setInputText(v),
              quotedMessage: _quotedMessage,
              onQuoteRemove: () { _quotedMessage = null; setState(() {}); },
              isLoading: chat.isLoading,
              onStop: () => chat.stop(),
              onSend: _sendMessage,
              onImagePick: () {},
              speechInputEnabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, String name, String emoji, AgentProvider agentProv) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF4A148C), Color(0xFF6A1B9A)]),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)])),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('AI 在线', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
              ],
            ),
          ),
          IconButton(onPressed: () => showDialog(context: context, builder: (_) => const AgentSwitcherDialog()), icon: const Icon(Icons.swap_horiz, color: Colors.white)),
          IconButton(
            onPressed: () => Provider.of<ChatProvider>(context, listen: false).clearMessages(),
            icon: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())), icon: const Icon(Icons.settings, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCreditsBar(AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: const Color(0xFFFFF8E1),
      child: Row(
        children: [
          const Text('💰', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(child: Text('积分: ${auth.creditsBalance}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFE65100)))),
          if (auth.creditsBalance < 1) const Text('⚠ 积分不足', style: TextStyle(fontSize: 11, color: Color(0xFFD32F2F))),
        ],
      ),
    );
  }

  Widget _buildWelcome(ThemeData theme, String name) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('你好，我是 $name', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('有什么可以帮助你的吗？', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: ['帮我写一段Python代码', '解释一下量子计算', '生成一张风景图', '帮我翻译这段文字']
                .map((t) => ActionChip(label: Text(t), onPressed: () {
                      Provider.of<ChatProvider>(context, listen: false).setInputText(t);
                      _inputFocus.requestFocus();
                    }))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolProgress(ChatProvider chat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: const Color(0xFFFFF8E1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: chat.toolProgress.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B))),
                    const SizedBox(width: 8),
                    Text(e.value, style: const TextStyle(fontSize: 13, color: Color(0xFF795548))),
                  ]),
                )).toList(),
          ),
        ),
      ),
    );
  }
}
