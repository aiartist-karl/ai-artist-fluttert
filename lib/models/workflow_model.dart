import 'dart:convert';
import 'package:uuid/uuid.dart';

/// 工作流节点类型枚举
/// 对应 Android: WorkflowNodeType enum
enum WorkflowNodeType {
  agent,
  tool,
  condition,
  delay,
  loop,
  start,
  end,
  setVariable,
  output;

  static WorkflowNodeType fromString(String value) {
    return WorkflowNodeType.values.firstWhere(
      (e) => e.name == value || e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => WorkflowNodeType.agent,
    );
  }

  /// 显示名称
  String get displayName {
    switch (this) {
      case WorkflowNodeType.agent:
        return 'Agent';
      case WorkflowNodeType.tool:
        return 'Tool';
      case WorkflowNodeType.condition:
        return 'Condition';
      case WorkflowNodeType.delay:
        return 'Delay';
      case WorkflowNodeType.loop:
        return 'Loop';
      case WorkflowNodeType.setVariable:
        return 'Set Variable';
      case WorkflowNodeType.output:
        return 'Output';
      case WorkflowNodeType.start:
        return 'Start';
      case WorkflowNodeType.end:
        return 'End';
    }
  }
}

/// 节点位置
/// 对应 Android: NodePosition
class NodePosition {
  final double x;
  final double y;

  const NodePosition({this.x = 0, this.y = 0});

  factory NodePosition.fromJson(Map<String, dynamic> json) {
    return NodePosition(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

/// 节点配置基类
/// 对应 Android: NodeConfig sealed class
abstract class NodeConfig {
  Map<String, dynamic> toJson();

  static NodeConfig fromJson(WorkflowNodeType type, Map<String, dynamic> json) {
    switch (type) {
      case WorkflowNodeType.agent:
        return AgentNodeConfig.fromJson(json);
      case WorkflowNodeType.tool:
        return ToolNodeConfig.fromJson(json);
      case WorkflowNodeType.condition:
        return ConditionNodeConfig.fromJson(json);
      case WorkflowNodeType.delay:
        return DelayNodeConfig.fromJson(json);
      case WorkflowNodeType.loop:
        return LoopNodeConfig.fromJson(json);
      case WorkflowNodeType.setVariable:
        return SetVariableNodeConfig.fromJson(json);
      case WorkflowNodeType.output:
        return OutputNodeConfig.fromJson(json);
      case WorkflowNodeType.start:
        return StartNodeConfig.fromJson(json);
      case WorkflowNodeType.end:
        return EndNodeConfig.fromJson(json);
    }
  }
}

/// Agent 节点配置
class AgentNodeConfig extends NodeConfig {
  final String agentId;
  final String prompt;
  final String modelId;

  AgentNodeConfig({this.agentId = '', this.prompt = '', this.modelId = ''});

  factory AgentNodeConfig.fromJson(Map<String, dynamic> json) {
    return AgentNodeConfig(
      agentId: json['agentId'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      modelId: json['modelId'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'prompt': prompt,
        'modelId': modelId,
      };
}

/// 工具节点配置
class ToolNodeConfig extends NodeConfig {
  final String pluginId;
  final Map<String, dynamic> params;

  ToolNodeConfig({this.pluginId = '', this.params = const {}});

  factory ToolNodeConfig.fromJson(Map<String, dynamic> json) {
    return ToolNodeConfig(
      pluginId: json['pluginId'] as String? ?? '',
      params: json['params'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'params': params,
      };
}

/// 条件节点配置
class ConditionNodeConfig extends NodeConfig {
  final String expression;
  final String trueBranch;
  final String falseBranch;

  ConditionNodeConfig({
    this.expression = '',
    this.trueBranch = '',
    this.falseBranch = '',
  });

  factory ConditionNodeConfig.fromJson(Map<String, dynamic> json) {
    return ConditionNodeConfig(
      expression: json['expression'] as String? ?? '',
      trueBranch: json['trueBranch'] as String? ?? '',
      falseBranch: json['falseBranch'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'expression': expression,
        'trueBranch': trueBranch,
        'falseBranch': falseBranch,
      };
}

/// 延迟节点配置
class DelayNodeConfig extends NodeConfig {
  final int durationMs;

  DelayNodeConfig({this.durationMs = 1000});

  factory DelayNodeConfig.fromJson(Map<String, dynamic> json) {
    return DelayNodeConfig(durationMs: json['durationMs'] as int? ?? 1000);
  }

  @override
  Map<String, dynamic> toJson() => {'durationMs': durationMs};
}

/// 循环节点配置
class LoopNodeConfig extends NodeConfig {
  final int count;
  final String iteratorVariable;
  final String collectionVariable;

  LoopNodeConfig({
    this.count = 1,
    this.iteratorVariable = 'i',
    this.collectionVariable = '',
  });

  factory LoopNodeConfig.fromJson(Map<String, dynamic> json) {
    return LoopNodeConfig(
      count: json['count'] as int? ?? 1,
      iteratorVariable: json['iteratorVariable'] as String? ?? 'i',
      collectionVariable: json['collectionVariable'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'count': count,
        'iteratorVariable': iteratorVariable,
        'collectionVariable': collectionVariable,
      };
}

/// 设置变量节点配置
class SetVariableNodeConfig extends NodeConfig {
  final String variableName;
  final String value;

  SetVariableNodeConfig({this.variableName = '', this.value = ''});

  factory SetVariableNodeConfig.fromJson(Map<String, dynamic> json) {
    return SetVariableNodeConfig(
      variableName: json['variableName'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'variableName': variableName,
        'value': value,
      };
}

/// 输出节点配置
class OutputNodeConfig extends NodeConfig {
  final String label;

  OutputNodeConfig({this.label = ''});

  factory OutputNodeConfig.fromJson(Map<String, dynamic> json) {
    return OutputNodeConfig(label: json['label'] as String? ?? '');
  }

  @override
  Map<String, dynamic> toJson() => {'label': label};
}

/// 开始节点配置
class StartNodeConfig extends NodeConfig {
  final List<String> inputVariables;

  StartNodeConfig({this.inputVariables = const []});

  factory StartNodeConfig.fromJson(Map<String, dynamic> json) {
    return StartNodeConfig(
      inputVariables: (json['inputVariables'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() => {'inputVariables': inputVariables};
}

/// 结束节点配置
class EndNodeConfig extends NodeConfig {
  final String outputExpression;

  EndNodeConfig({this.outputExpression = ''});

  factory EndNodeConfig.fromJson(Map<String, dynamic> json) {
    return EndNodeConfig(outputExpression: json['outputExpression'] as String? ?? '');
  }

  @override
  Map<String, dynamic> toJson() => {'outputExpression': outputExpression};
}

/// 工作流节点
/// 对应 Android: WorkflowNode
class WorkflowNode {
  final String id;
  final WorkflowNodeType type;
  String name;
  NodePosition position;
  NodeConfig config;

  WorkflowNode({
    String? id,
    required this.type,
    this.name = '',
    this.position = const NodePosition(),
    NodeConfig? config,
  })  : id = id ?? const Uuid().v4(),
        config = config ?? _defaultConfigForType(type);

  factory WorkflowNode.fromJson(Map<String, dynamic> json) {
    final type = WorkflowNodeType.fromString(json['type'] as String);
    final node = WorkflowNode(
      id: json['id'] as String,
      type: type,
      name: json['name'] as String? ?? '',
      position: NodePosition.fromJson(json['position'] as Map<String, dynamic>? ?? {}),
      config: NodeConfig.fromJson(type, json['config'] as Map<String, dynamic>? ?? {}),
    );
    return node;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name.toUpperCase(),
        'name': name,
        'position': position.toJson(),
        'config': config.toJson(),
      };

  String get displayName => name.isNotEmpty ? name : type.displayName;

  static NodeConfig _defaultConfigForType(WorkflowNodeType type) {
    switch (type) {
      case WorkflowNodeType.agent:
        return AgentNodeConfig();
      case WorkflowNodeType.tool:
        return ToolNodeConfig();
      case WorkflowNodeType.condition:
        return ConditionNodeConfig();
      case WorkflowNodeType.delay:
        return DelayNodeConfig();
      case WorkflowNodeType.loop:
        return LoopNodeConfig();
      case WorkflowNodeType.setVariable:
        return SetVariableNodeConfig();
      case WorkflowNodeType.output:
        return OutputNodeConfig();
      case WorkflowNodeType.start:
        return StartNodeConfig();
      case WorkflowNodeType.end:
        return EndNodeConfig();
    }
  }
}

/// 工作流连接
/// 对应 Android: WorkflowConnection
class WorkflowConnection {
  final String id;
  final String sourceNodeId;
  final String targetNodeId;
  final String sourcePort;
  final String targetPort;
  final String label;

  WorkflowConnection({
    String? id,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.sourcePort = 'output',
    this.targetPort = 'input',
    this.label = '',
  }) : id = id ?? const Uuid().v4();

  factory WorkflowConnection.fromJson(Map<String, dynamic> json) {
    return WorkflowConnection(
      id: json['id'] as String? ?? const Uuid().v4(),
      sourceNodeId: json['sourceNodeId'] as String? ?? '',
      targetNodeId: json['targetNodeId'] as String? ?? '',
      sourcePort: json['sourcePort'] as String? ?? 'output',
      targetPort: json['targetPort'] as String? ?? 'input',
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceNodeId': sourceNodeId,
        'targetNodeId': targetNodeId,
        'sourcePort': sourcePort,
        'targetPort': targetPort,
        'label': label,
      };
}

/// 工作流定义
/// 对应 Android: Workflow
class Workflow {
  final String id;
  String name;
  String description;
  final List<WorkflowNode> nodes;
  final List<WorkflowConnection> connections;
  final Map<String, dynamic> variables;
  int createdAt;
  int updatedAt;
  bool enabled;

  Workflow({
    String? id,
    this.name = 'Untitled Workflow',
    this.description = '',
    List<WorkflowNode>? nodes,
    List<WorkflowConnection>? connections,
    Map<String, dynamic>? variables,
    int? createdAt,
    int? updatedAt,
    this.enabled = true,
  })  : id = id ?? const Uuid().v4(),
        nodes = nodes ?? [],
        connections = connections ?? [],
        variables = variables ?? {},
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  factory Workflow.fromJson(Map<String, dynamic> json) {
    final workflow = Workflow(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Untitled Workflow',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] as int?,
      updatedAt: json['updatedAt'] as int?,
      enabled: json['enabled'] as bool? ?? true,
    );

    final nodesJson = json['nodes'] as List<dynamic>? ?? [];
    for (final nodeJson in nodesJson) {
      workflow.nodes.add(WorkflowNode.fromJson(nodeJson as Map<String, dynamic>));
    }

    final connectionsJson = json['connections'] as List<dynamic>? ?? [];
    for (final connJson in connectionsJson) {
      workflow.connections.add(WorkflowConnection.fromJson(connJson as Map<String, dynamic>));
    }

    final varsJson = json['variables'] as Map<String, dynamic>? ?? {};
    workflow.variables.addAll(varsJson);

    return workflow;
  }

  factory Workflow.fromJsonString(String jsonString) {
    return Workflow.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'enabled': enabled,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'connections': connections.map((c) => c.toJson()).toList(),
        'variables': variables,
      };

  String toJsonString() => jsonEncode(toJson());

  /// 获取从某节点出发的所有连接
  List<WorkflowConnection> outgoingConnections(String nodeId) =>
      connections.where((c) => c.sourceNodeId == nodeId).toList();

  /// 获取指向某节点的所有连接
  List<WorkflowConnection> incomingConnections(String nodeId) =>
      connections.where((c) => c.targetNodeId == nodeId).toList();

  /// 按 ID 查找节点
  WorkflowNode? getNode(String nodeId) {
    try {
      return nodes.firstWhere((n) => n.id == nodeId);
    } catch (_) {
      return null;
    }
  }

  /// 获取起始节点
  WorkflowNode? startNode() {
    try {
      return nodes.firstWhere((n) => n.type == WorkflowNodeType.start);
    } catch (_) {
      return null;
    }
  }

  /// 获取所有结束节点
  List<WorkflowNode> endNodes() =>
      nodes.where((n) => n.type == WorkflowNodeType.end).toList();

  /// 验证工作流结构
  List<String> validate() {
    final errors = <String>[];

    if (nodes.isEmpty) {
      errors.add('Workflow has no nodes');
      return errors;
    }

    final startNodes = nodes.where((n) => n.type == WorkflowNodeType.start).toList();
    if (startNodes.isEmpty) {
      errors.add('Workflow must have a Start node');
    } else if (startNodes.length > 1) {
      errors.add('Workflow must have exactly one Start node (found ${startNodes.length})');
    }

    final endNodesList = nodes.where((n) => n.type == WorkflowNodeType.end).toList();
    if (endNodesList.isEmpty) {
      errors.add('Workflow must have at least one End node');
    }

    final connectedIds = <String>{};
    for (final conn in connections) {
      connectedIds.add(conn.sourceNodeId);
      connectedIds.add(conn.targetNodeId);
    }
    final orphans = nodes
        .where((n) => !connectedIds.contains(n.id) && n.type != WorkflowNodeType.start)
        .toList();
    if (orphans.isNotEmpty) {
      errors.add('Orphan nodes found: ${orphans.map((n) => n.displayName).join(', ')}');
    }

    return errors;
  }
}
