import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../models/history_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};
  bool _favoriteOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hp = Provider.of<HistoryProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '已选 ${_selectedIds.length} 项' : '历史对话'),
        leading: _isSelectionMode ? IconButton(icon: const Icon(Icons.close), onPressed: () { setState(() { _isSelectionMode = false; _selectedIds.clear(); }); }) : null,
        actions: [
          IconButton(icon: Icon(_favoriteOnly ? Icons.favorite : Icons.favorite_border, color: _favoriteOnly ? Colors.red : null), onPressed: () { setState(() => _favoriteOnly = !_favoriteOnly); hp.setFilterFavoritesOnly(_favoriteOnly); }),
          if (_isSelectionMode) ...[
            IconButton(icon: const Icon(Icons.select_all), onPressed: () {
              setState(() {
                if (_selectedIds.length == hp.items.length) { _selectedIds.clear(); _isSelectionMode = false; }
                else _selectedIds.addAll(hp.items.map((e) => e.id));
              });
            }),
            IconButton(icon: const Icon(Icons.delete), onPressed: () => _batchDelete(hp)),
          ],
        ],
      ),
      body: hp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : hp.items.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.history, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('暂无历史记录', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(12), itemCount: hp.items.length,
                  itemBuilder: (context, index) {
                    final item = hp.items[index];
                    final isSelected = _selectedIds.contains(item.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected ? theme.colorScheme.primaryContainer : null,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (_isSelectionMode) {
                            setState(() {
                              if (isSelected) { _selectedIds.remove(item.id); if (_selectedIds.isEmpty) _isSelectionMode = false; }
                              else _selectedIds.add(item.id);
                            });
                          }
                        },
                        onLongPress: () => setState(() { _isSelectionMode = true; _selectedIds.add(item.id); }),
                        child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                          if (_isSelectionMode) Checkbox(value: isSelected, onChanged: (_) {}),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.prompt.isNotEmpty ? item.prompt : item.modelId, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('${item.modelId} • ${DateTime.fromMillisecondsSinceEpoch(item.timestamp).toString().substring(0, 16)}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ])),
                          IconButton(icon: Icon(item.favorite ? Icons.favorite : Icons.favorite_border, color: item.favorite ? Colors.red : null, size: 20), onPressed: () => hp.setFavorite(item.id, !item.favorite)),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => hp.deleteItem(item)),
                        ])),
                      ),
                    );
                  },
                ),
    );
  }

  void _batchDelete(HistoryProvider hp) {
    final items = hp.items.where((i) => _selectedIds.contains(i.id)).toList();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('批量删除'),
      content: Text('确定要删除选中的 ${items.length} 条记录吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        TextButton(onPressed: () {
          hp.deleteItems(items);
          setState(() { _selectedIds.clear(); _isSelectionMode = false; });
          Navigator.pop(ctx);
        }, child: const Text('删除', style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}
