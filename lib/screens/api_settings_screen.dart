import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});
  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  late TextEditingController _oHostCtrl, _oModelCtrl, _aiHostCtrl, _aiKeyCtrl, _aiModelCtrl;
  late TextEditingController _ttsIdCtrl, _ttsTokenCtrl, _imgUrlCtrl, _imgKeyCtrl;
  late TextEditingController _whUrlCtrl, _whTplCtrl, _bsUrlCtrl, _bsTokenCtrl;

  @override
  void initState() {
    super.initState();
    final s = Provider.of<SettingsProvider>(context, listen: false);
    _oHostCtrl = TextEditingController(text: s.ollamaHost);
    _oModelCtrl = TextEditingController(text: s.ollamaModel);
    _aiHostCtrl = TextEditingController(text: s.openAIHost);
    _aiKeyCtrl = TextEditingController(text: s.openAIApiKey);
    _aiModelCtrl = TextEditingController(text: s.openAIModel);
    _ttsIdCtrl = TextEditingController(text: s.ttsAppId);
    _ttsTokenCtrl = TextEditingController(text: s.ttsAccessToken);
    _imgUrlCtrl = TextEditingController(text: s.imageApiUrl);
    _imgKeyCtrl = TextEditingController(text: s.imageApiKey);
    _whUrlCtrl = TextEditingController(text: s.webhookUrl);
    _whTplCtrl = TextEditingController(text: s.webhookTemplate);
    _bsUrlCtrl = TextEditingController(text: s.buildServerUrl);
    _bsTokenCtrl = TextEditingController(text: s.buildServerToken);
  }

  @override
  void dispose() { _oHostCtrl.dispose(); _oModelCtrl.dispose(); _aiHostCtrl.dispose(); _aiKeyCtrl.dispose(); _aiModelCtrl.dispose(); _ttsIdCtrl.dispose(); _ttsTokenCtrl.dispose(); _imgUrlCtrl.dispose(); _imgKeyCtrl.dispose(); _whUrlCtrl.dispose(); _whTplCtrl.dispose(); _bsUrlCtrl.dispose(); _bsTokenCtrl.dispose(); super.dispose(); }

  void _saved() { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('设置已保存'), duration: Duration(seconds: 1))); }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('API 设置')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [Icon(Icons.cloud, size: 32, color: theme.colorScheme.primary), const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('API 设置', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text('配置本地大模型 API 连接', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ])]),
        const SizedBox(height: 16), const Divider(), const SizedBox(height: 16),

        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('API 类型', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(segments: const [ButtonSegment(value: 'ollama', label: Text('Ollama')), ButtonSegment(value: 'openai', label: Text('OpenAI 兼容'))],
            selected: {s.chatApiType}, onSelectionChanged: (v) => s.setChatApiType(v.first)),
        ]))),
        const SizedBox(height: 16),

        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ollama 设置', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _oHostCtrl, decoration: const InputDecoration(labelText: 'Ollama 地址')),
          const SizedBox(height: 8),
          TextField(controller: _oModelCtrl, decoration: const InputDecoration(labelText: 'Ollama 模型')),
          const SizedBox(height: 12),
          FilledButton(onPressed: () { s.setOllamaHost(_oHostCtrl.text); s.setOllamaModel(_oModelCtrl.text); _saved(); }, child: const Text('保存 Ollama 设置')),
        ]))),
        const SizedBox(height: 16),

        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('OpenAI 兼容设置', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _aiHostCtrl, decoration: const InputDecoration(labelText: 'API 地址')),
          const SizedBox(height: 8),
          TextField(controller: _aiKeyCtrl, decoration: const InputDecoration(labelText: 'API Key'), obscureText: true),
          const SizedBox(height: 8),
          TextField(controller: _aiModelCtrl, decoration: const InputDecoration(labelText: '模型名称')),
          const SizedBox(height: 12),
          FilledButton(onPressed: () { s.setOpenAIHost(_aiHostCtrl.text); s.setOpenAIApiKey(_aiKeyCtrl.text); s.setOpenAIModel(_aiModelCtrl.text); _saved(); }, child: const Text('保存 OpenAI 设置')),
        ]))),
        const SizedBox(height: 16),

        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('语音设置', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(title: const Text('启用语音输出 (TTS)'), value: s.ttsEnabled, onChanged: (v) => s.setTtsEnabled(v)),
          SwitchListTile(title: const Text('启用语音输入'), value: s.speechInputEnabled, onChanged: (v) => s.setSpeechInputEnabled(v)),
          TextField(controller: _ttsIdCtrl, decoration: const InputDecoration(labelText: '火山引擎 App ID')),
          const SizedBox(height: 8),
          TextField(controller: _ttsTokenCtrl, decoration: const InputDecoration(labelText: '火山引擎 Access Token'), obscureText: true),
          const SizedBox(height: 8),
          Row(children: [Text('语速: ${s.ttsSpeed.toStringAsFixed(1)}x'), Expanded(child: Slider(value: s.ttsSpeed, min: 0.5, max: 2.0, divisions: 5, onChanged: (v) => s.setTtsSpeed(v)))]),
          const SizedBox(height: 8),
          FilledButton(onPressed: () { s.setTtsAppId(_ttsIdCtrl.text); s.setTtsAccessToken(_ttsTokenCtrl.text); _saved(); }, child: const Text('保存语音设置')),
        ]))),
        const SizedBox(height: 16),

        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('生图 API 设置', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _imgUrlCtrl, decoration: const InputDecoration(labelText: '图片生成 API 地址')),
          const SizedBox(height: 8),
          TextField(controller: _imgKeyCtrl, decoration: const InputDecoration(labelText: '图片生成 API Key'), obscureText: true),
          const SizedBox(height: 12),
          FilledButton(onPressed: () { s.setImageApiUrl(_imgUrlCtrl.text); s.setImageApiKey(_imgKeyCtrl.text); _saved(); }, child: const Text('保存生图设置')),
        ]))),
        const SizedBox(height: 16),

        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Webhook 通知', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(title: const Text('启用 Webhook 通知'), value: s.webhookEnabled, onChanged: (v) => s.setWebhookEnabled(v)),
          TextField(controller: _whUrlCtrl, decoration: const InputDecoration(labelText: 'Webhook URL')),
          const SizedBox(height: 8),
          TextField(controller: _whTplCtrl, decoration: const InputDecoration(labelText: '通知模板 (JSON)'), maxLines: 3),
          const SizedBox(height: 4),
          Text('变量: {event} {message} {timestamp}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          FilledButton(onPressed: () { s.setWebhookUrl(_whUrlCtrl.text); s.setWebhookTemplate(_whTplCtrl.text); _saved(); }, child: const Text('保存 Webhook 设置')),
        ]))),
        const SizedBox(height: 16),

        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🔧 编译服务器 (Build Server)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('配置后 AI 可以远程修改代码并编译。', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextField(controller: _bsUrlCtrl, decoration: const InputDecoration(labelText: '服务器地址', hintText: 'http://192.168.1.100:9527')),
          const SizedBox(height: 8),
          TextField(controller: _bsTokenCtrl, decoration: const InputDecoration(labelText: 'Token'), obscureText: true),
          const SizedBox(height: 12),
          FilledButton(onPressed: () { s.setBuildServerUrl(_bsUrlCtrl.text); s.setBuildServerToken(_bsTokenCtrl.text); _saved(); }, child: const Text('保存编译服务器设置')),
        ]))),
        const SizedBox(height: 16),

        Card(color: theme.colorScheme.primaryContainer.withOpacity(0.2), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.smart_toy, size: 20), SizedBox(width: 8), Text('推荐模型', style: TextStyle(fontWeight: FontWeight.w600))]),
          const SizedBox(height: 8),
          _rec(theme, 'deepseek-r1-distill-qwen-14b', '推理能力最强（~10G显存）'),
          _rec(theme, 'qwen2:14b', '中文能力优秀（~8G显存）'),
          _rec(theme, 'llama3:8b', '轻量级通用模型（~5G显存）'),
        ]))),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _rec(ThemeData t, String m, String d) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
    Text(m, style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: t.colorScheme.primary)),
    const SizedBox(width: 8),
    Text(d, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
  ]));
}
