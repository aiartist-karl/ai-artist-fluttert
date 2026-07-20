import 'package:flutter/material.dart';

class CreationScreen extends StatefulWidget {
  const CreationScreen({super.key});
  @override
  State<CreationScreen> createState() => _CreationScreenState();
}

class _CreationScreenState extends State<CreationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _posCtrl = TextEditingController();
  final _negCtrl = TextEditingController();
  String _resolution = '1024×1024';
  bool _generating = false;
  String? _resultUrl;
  String? _error;
  static const _res = ['1024×1024','768×1024','576×1024','1024×1536','1024×1792','1024×768','1024×576','1536×1024','1792×1024'];

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); _posCtrl.dispose(); _negCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('创作'), bottom: TabBar(controller: _tabCtrl, tabs: const [Tab(icon: Icon(Icons.create), text: '文生图'), Tab(icon: Icon(Icons.image), text: '图生图')])),
      body: TabBarView(controller: _tabCtrl, children: [_txt2img(theme), _img2img(theme)]),
    );
  }

  Widget _txt2img(ThemeData theme) => ListView(padding: const EdgeInsets.all(16), children: [
    TextField(controller: _posCtrl, decoration: const InputDecoration(labelText: '正面提示词', hintText: '描述你想要生成的图片内容...'), minLines: 2, maxLines: 4),
    const SizedBox(height: 12),
    TextField(controller: _negCtrl, decoration: const InputDecoration(labelText: '负面提示词（可选）', hintText: '描述你不想要的内容...'), minLines: 1, maxLines: 2),
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(value: _resolution, decoration: const InputDecoration(labelText: '分辨率'),
      items: _res.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
      onChanged: (v) { if (v != null) setState(() => _resolution = v); }),
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(
      onPressed: _generating ? null : _gen,
      icon: _generating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
      label: Text(_generating ? '生成中...' : '生成图片'))),
    const SizedBox(height: 24),
    if (_error != null) Card(color: Theme.of(context).colorScheme.errorContainer, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!))),
    if (_resultUrl != null) Card(child: Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_resultUrl!, fit: BoxFit.cover)),
      Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.save), label: const Text('保存')),
        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.share), label: const Text('分享')),
      ])),
    ])),
  ]);

  Widget _img2img(ThemeData theme) => ListView(padding: const EdgeInsets.all(16), children: [
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      const Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
      const SizedBox(height: 8), const Text('点击上传参考图片'),
      const SizedBox(height: 12), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.image), label: const Text('选择图片')),
    ]))),
    const SizedBox(height: 16),
    TextField(controller: _posCtrl, decoration: const InputDecoration(labelText: '正面提示词'), minLines: 2, maxLines: 4),
    const SizedBox(height: 12),
    TextField(controller: _negCtrl, decoration: const InputDecoration(labelText: '负面提示词（可选）'), minLines: 1, maxLines: 2),
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(onPressed: _generating ? null : _gen, icon: const Icon(Icons.auto_awesome), label: const Text('生成图片'))),
  ]);

  void _gen() {
    setState(() { _generating = true; _error = null; _resultUrl = null; });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() { _generating = false; _error = '请配置生图API后使用'; });
    });
  }
}
