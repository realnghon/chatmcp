import 'dart:convert';
import 'package:uuid/uuid.dart';

// 消息角色枚举
enum MessageRole {
  system,
  user,
  assistant,
  function,
  tool,
  error,
  loading;

  String get value => name;
}

class File {
  final String name;
  final int size;
  final String? path;
  final String fileType;
  final String fileContent;

  File({
    required this.name,
    required this.path,
    required this.size,
    required this.fileType,
    this.fileContent = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'size': size,
      'fileType': fileType,
      'fileContent': fileContent,
    };
  }

  factory File.fromJson(Map<String, dynamic> json) {
    return File(
      name: json['name'],
      path: json['path'],
      size: json['size'],
      fileType: json['fileType'],
      fileContent: json['fileContent'],
    );
  }
}

// 消息结构体
class ChatMessage {
  final String uuid;
  final MessageRole role;
  final String? content;
  final String? name;
  final String? mcpServerName;
  final String? toolCallId;
  final List<Map<String, dynamic>>? toolCalls;
  final List<File>? files;

  ChatMessage({
    String? uuid,
    required this.role,
    this.content,
    this.name,
    this.mcpServerName,
    this.toolCallId,
    this.toolCalls,
    this.files,
  }) : uuid = uuid ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'role': role.value,
      if (content != null) 'content': content,
    };

    if (role == MessageRole.tool && name != null && toolCallId != null) {
      json['name'] = name!;
      json['tool_call_id'] = toolCallId!;
    }

    if (toolCalls != null) {
      json['tool_calls'] = toolCalls;
    }

    if (mcpServerName != null) {
      json['mcpServerName'] = mcpServerName!;
    }

    if (files != null) {
      json['files'] = files?.map((file) => file.toJson()).toList();
    }

    return json;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // 处理 toolCalls 的类型转换
    List<Map<String, dynamic>>? toolCalls;
    if (json['tool_calls'] != null) {
      toolCalls = (json['tool_calls'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    List<File>? files;
    if (json['files'] != null) {
      files = (json['files'] as List)
          .map((item) => File.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return ChatMessage(
      role: MessageRole.values.firstWhere((e) => e.value == json['role']),
      content: json['content'],
      name: json['name'],
      mcpServerName: json['mcpServerName'],
      toolCallId: json['tool_call_id'],
      toolCalls: toolCalls,
      files: files,
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

// 添加工具调用的数据结构
class ToolCall {
  final String id;
  final String type;
  final FunctionCall function;

  ToolCall({
    required this.id,
    required this.type,
    required this.function,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'function': function.toJson(),
      };
}

class FunctionCall {
  final String name;
  final String arguments;

  FunctionCall({
    required this.name,
    required this.arguments,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'arguments': arguments,
      };

  // 解析参数为 Map
  Map<String, dynamic> get parsedArguments =>
      json.decode(arguments) as Map<String, dynamic>;
}

class LLMResponse {
  final String? content;
  final List<ToolCall>? toolCalls;
  final bool needToolCall;

  LLMResponse({
    this.content,
    this.toolCalls,
  }) : needToolCall = toolCalls != null && toolCalls.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'content': content,
        'tool_calls': toolCalls?.map((t) => t.toJson()).toList(),
        'need_tool_call': needToolCall,
      };
}

class Model {
  final String name;
  final String label;
  final String provider;

  Model({
    required this.name,
    required this.label,
    required this.provider,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      name: json['name'],
      label: json['label'],
      provider: json['provider'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'label': label,
        'provider': provider,
      };

  @override
  String toString() => jsonEncode(toJson());
}

class CompletionRequest {
  final String model;
  final List<ChatMessage> messages;
  final List<Map<String, dynamic>>? tools;
  final bool stream;

  CompletionRequest({
    required this.model,
    required this.messages,
    this.tools,
    this.stream = false,
  });
}
