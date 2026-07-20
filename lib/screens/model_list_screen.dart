import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ModelListScreen extends StatefulWidget {
  const ModelListScreen({super.key});
  @override
  State<ModelListScreen> createState() => _ModelListScreenState();
}

class _ModelListScreenState extends State<ModelListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('模型列表'), bottom: TabBar(controller: _tabCtrl, tabs: const [Tab(text: '本地模型'), Tab(text: '云端模型')])),
      body: TabBarView(controller: _tabCtrl, children: [
        ListView(padding: const EdgeInsets.all(12), children: [
          _modelCard(context, s.ollamaModel, 'ollama', isSelected: s.chatApiType == 'ollama' && s.ollamaModel == s.ollamaModel,
            onSelect: () { s.setChatApiType('ollama'); }),
        ]),
        ListView(padding: const EdgeInsets.all(12), children: [
          _modelCard(context, s.openAIModel, 'openai', isSelected: s.chatApiType == 'openai',
            onSelect: () { s.setChatApiType('openai'); }),
          _modelCard(context, 'gpt-4o-mini', 'openai', isSelected: s.chatApiType == 'openai' && s.openAIModel == 'gpt-4o-mini',
            onSelect: () { s.setChatApiType('openai'); s.setOpenAIModel('gpt-4o-mini'); }),
          _modelCard(context, 'deepseek-chat', 'openai', isSelected: s.chatApiType == 'openai' && s.openAIModel == 'deepseek-chat',
            onSelect: () { s.setChatApiType('openai'); s.setOpenAIModel('deepseek-chat'); }),
        ]),
      ]),
    );
  }

  Widget _modelCard(BuildContext context, String name, String type, {required bool isSelected, required VoidCallback onSelect}) {
    final theme = Theme.of(context);
    return Card(margin: const EdgeInsets.only(bottom: 8), color: isSelected ? theme.colorScheme.primaryContainer : null, elevation: isSelected ? 3 : 1,
      child: ListTile(
        leading: Icon(type == 'ollama' ? Icons.dns : Icons.cloud, color: isSelected ? theme.colorScheme.primary : null),
        title: Text(name.isEmpty ? '(未配置)' : name, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(type),
        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF10B981)) : null,
        onTap: onSelect,
      ));
  }
}
