import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agent_model.dart';

/// Agent 持久化服务
/// 对应 Android AgentRepository.kt 的 SharedPreferences 存储逻辑
class AgentService {
  static const String _keyAgentsList = 'agents_list';
  static const String _keyActiveAgentId = 'active_agent_id';

  static Future<List<Agent>> loadAgents() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyAgentsList);
    if (json == null || json.isEmpty) {
      return [Agent.defaultAgent()];
    }
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => Agent.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [Agent.defaultAgent()];
    }
  }

  static Future<void> saveAgents(List<Agent> agents) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(agents.map((a) => a.toJson()).toList());
    await prefs.setString(_keyAgentsList, json);
  }

  static Future<String> getActiveAgentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveAgentId) ?? 'default';
  }

  static Future<void> setActiveAgentId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveAgentId, id);
  }
}
