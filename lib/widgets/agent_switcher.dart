import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../utils/theme.dart';

class AgentSwitcherDialog extends StatelessWidget {
  const AgentSwitcherDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context);
    final agents = agentProvider.agents;
    final activeId = agentProvider.activeAgentId;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Color(0xFF667EEA)),
          const SizedBox(width: 8),
          const Text('切换 Agent', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: agents.map((agent) {
            final isActive = agent.id == activeId;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                leading: Text(agent.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(agent.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                subtitle: agent.description.isNotEmpty
                    ? Text(agent.description, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))
                    : null,
                trailing: isActive ? const Text('✓', style: TextStyle(color: Color(0xFF667EEA), fontWeight: FontWeight.bold, fontSize: 18)) : null,
                onTap: () {
                  agentProvider.setActiveAgent(agent.id);
                  Navigator.pop(context);
                },
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
      ],
    );
  }
}
