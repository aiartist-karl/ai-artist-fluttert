import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../models/agent_model.dart';
import '../utils/theme.dart';

class AgentManagementScreen extends StatelessWidget {
  const AgentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AgentProvider>(context);
    final agents = ap.agents;
    final activeId = ap.activeAgentId;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent 管理'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showEdit(context, null))],
      ),
      body: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)), child: const Icon(Icons.smart_toy, color: Colors.white)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Agent 管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('共 ${agents.length} 个 Agent', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
            ]),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12), itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              final isActive = agent.id == activeId;
              return _AgentCard(
                agent: agent, isActive: isActive,
                onSelect: () => ap.setActiveAgent(agent.id),
                onEdit: () => _showEdit(context, agent),
                onDelete: agents.length > 1 ? () => _confirmDelete(context, agent, ap) : null,
              );
            },
          ),
        ),
      ]),
    );
  }

  void _showEdit(BuildContext context, Agent? existing) {
    showDialog(context: context, builder: (_) => _AgentEditDialog(agent: existing));
  }

  void _confirmDelete(BuildContext context, Agent agent, AgentProvider ap) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      title: const Text('删除 Agent'),
      content: Text('确定要删除「${agent.name}」吗？此操作不可恢复。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        TextButton(onPressed: () { ap.deleteAgent(agent.id); Navigator.pop(ctx); }, child: const Text('删除', style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}

class _AgentCard extends StatelessWidget {
  final Agent agent;
  final bool isActive;
  final VoidCallback onSelect, onEdit;
  final VoidCallback? onDelete;

  const _AgentCard({required this.agent, required this.isActive, required this.onSelect, required this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isActive ? theme.colorScheme.primaryContainer : null,
      elevation: isActive ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16), onTap: onSelect,
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: isActive ? AppTheme.primaryGradient : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300])),
            alignment: Alignment.center,
            child: Text(agent.emoji, style: const TextStyle(fontSize: 24))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(agent.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (isActive) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(4)),
                child: const Text('使用中', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)))],
            ]),
            if (agent.description.isNotEmpty) Text(agent.description, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('模型: ${agent.model.isNotEmpty ? agent.model : (agent.apiType == 'openai' ? '默认 OpenAI 模型' : '默认 Ollama 模型')}',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
          ])),
          Column(children: [
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, color: Color(0xFF4A90E2), size: 18)),
            if (onDelete != null) IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18)),
          ]),
        ])),
      ),
    );
  }
}

class _AgentEditDialog extends StatefulWidget {
  final Agent? agent;
  const _AgentEditDialog({this.agent});
  @override
  State<_AgentEditDialog> createState() => _AgentEditDialogState();
}

class _AgentEditDialogState extends State<_AgentEditDialog> {
  late TextEditingController _name, _desc, _prompt, _host, _apiKey, _model;
  late String _apiType, _emoji;
  bool _showEmojiPicker = false;
  static const _emojis = ['🤖','🧠','🎨','📚','💡','🌟','🎯','🔬','✍️','🎭','🦊','🐱','🌈','⚡','🔮'];

  @override
  void initState() {
    super.initState();
    final a = widget.agent;
    _name = TextEditingController(text: a?.name ?? '');
    _desc = TextEditingController(text: a?.description ?? '');
    _prompt = TextEditingController(text: a?.systemPrompt ?? '你是一个有帮助的AI助手。请用中文回答用户的问题。');
    _host = TextEditingController(text: a?.host ?? '');
    _apiKey = TextEditingController(text: a?.apiKey ?? '');
    _model = TextEditingController(text: a?.model ?? '');
    _apiType = a?.apiType ?? 'openai';
    _emoji = a?.emoji ?? '🤖';
  }

  @override
  void dispose() { _name.dispose(); _desc.dispose(); _prompt.dispose(); _host.dispose(); _apiKey.dispose(); _model.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.agent != null;
    return AlertDialog(
      title: Row(children: [Icon(isEdit ? Icons.edit : Icons.add, color: const Color(0xFF667EEA)), const SizedBox(width: 8), Text(isEdit ? '编辑 Agent' : '新建 Agent', style: const TextStyle(fontWeight: FontWeight.bold))]),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          GestureDetector(onTap: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
            child: Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
              alignment: Alignment.center, child: Text(_emoji, style: const TextStyle(fontSize: 24)))),
          const SizedBox(width: 12), const Text('点击选择头像', style: TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
        if (_showEmojiPicker) Padding(padding: const EdgeInsets.only(top: 8),
          child: Wrap(spacing: 6, runSpacing: 6,
            children: _emojis.map((e) => GestureDetector(onTap: () => setState(() { _emoji = e; _showEmojiPicker = false; }),
              child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center, child: Text(e, style: const TextStyle(fontSize: 22))))).toList())),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: const InputDecoration(labelText: '名称 *', hintText: '例如: 代码助手、翻译专家')),
        const SizedBox(height: 8),
        TextField(controller: _desc, decoration: const InputDecoration(labelText: '描述', hintText: '简短描述这个 Agent 的用途')),
        const SizedBox(height: 8),
        TextField(controller: _prompt, decoration: const InputDecoration(labelText: '系统提示词'), minLines: 3, maxLines: 6),
        const SizedBox(height: 12), const Divider(), const SizedBox(height: 8),
        Row(children: [
          ChoiceChip(label: const Text('OpenAI 兼容'), selected: _apiType == 'openai', onSelected: (_) => setState(() => _apiType = 'openai')),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('Ollama'), selected: _apiType == 'ollama', onSelected: (_) => setState(() => _apiType = 'ollama')),
        ]),
        const SizedBox(height: 8),
        TextField(controller: _host, decoration: InputDecoration(labelText: 'API 地址（留空使用全局设置）', hintText: _apiType == 'openai' ? 'https://api.example.com/v1' : 'http://localhost:11434')),
        const SizedBox(height: 8),
        TextField(controller: _apiKey, decoration: const InputDecoration(labelText: 'API Key（留空使用全局设置）', hintText: 'sk-...')),
        const SizedBox(height: 8),
        TextField(controller: _model, decoration: InputDecoration(labelText: '模型名称（留空使用全局设置）', hintText: _apiType == 'openai' ? 'gpt-4o-mini' : 'llama3')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: _name.text.trim().isEmpty ? null : () {
            final ap = Provider.of<AgentProvider>(context, listen: false);
            final a = Agent(id: widget.agent?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: _name.text.trim(), description: _desc.text.trim(), emoji: _emoji,
              systemPrompt: _prompt.text.trim(), apiType: _apiType, host: _host.text.trim(),
              apiKey: _apiKey.text.trim(), model: _model.text.trim());
            if (isEdit) ap.updateAgent(a); else ap.addAgent(a);
            Navigator.pop(context);
          },
          child: Text(isEdit ? '保存' : '创建'),
        ),
      ],
    );
  }
}
