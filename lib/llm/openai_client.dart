import 'package:dio/dio.dart';
import 'base_llm_client.dart';
import 'dart:convert';
import 'model.dart';
import 'package:logging/logging.dart';
import 'package:ChatMcp/utils/file_content.dart';

class OpenAIClient extends BaseLLMClient {
  final String apiKey;
  final String baseUrl;
  final Dio _dio;

  OpenAIClient({
    required this.apiKey,
    String? baseUrl,
    Dio? dio,
  })  : baseUrl = (baseUrl == null || baseUrl.isEmpty)
            ? 'https://api.openai.com/v1'
            : baseUrl,
        _dio = dio ??
            Dio(BaseOptions(
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
              },
            ));

  @override
  Future<LLMResponse> chatCompletion(CompletionRequest request) async {
    final body = {
      'model': request.model,
      'messages': chatMessageToOpenAIMessage(request.messages),
    };

    if (request.modelSetting != null) {
      body['temperature'] = request.modelSetting!.temperature;
      body['top_p'] = request.modelSetting!.topP;
      body['frequency_penalty'] = request.modelSetting!.frequencyPenalty;
      body['presence_penalty'] = request.modelSetting!.presencePenalty;
      if (request.modelSetting!.maxTokens != null) {
        body['max_tokens'] = request.modelSetting!.maxTokens!;
      }
    }

    if (request.tools != null && request.tools!.isNotEmpty) {
      body['tools'] = request.tools!;
      body['tool_choice'] = 'auto';
    }

    final bodyStr = jsonEncode(body);

    try {
      final response = await _dio.post(
        "$baseUrl/chat/completions",
        data: bodyStr,
      );

      // 处理 ResponseBody 类型的响应
      var jsonData;
      if (response.data is ResponseBody) {
        final responseBody = response.data as ResponseBody;
        final responseStr = await utf8.decodeStream(responseBody.stream);
        jsonData = jsonDecode(responseStr);
      } else {
        jsonData = response.data;
      }

      final message = jsonData['choices'][0]['message'];

      // 解析工具调用
      final toolCalls = message['tool_calls']
          ?.map<ToolCall>((t) => ToolCall(
                id: t['id'],
                type: t['type'],
                function: FunctionCall(
                  name: t['function']['name'],
                  arguments: t['function']['arguments'],
                ),
              ))
          ?.toList();

      return LLMResponse(
        content: message['content'],
        toolCalls: toolCalls,
      );
    } catch (e) {
      throw await handleError(
          e, 'OpenAI', '$baseUrl/chat/completions', bodyStr);
    }
  }

  @override
  Stream<LLMResponse> chatStreamCompletion(CompletionRequest request) async* {
    final body = {
      'model': request.model,
      'messages': chatMessageToOpenAIMessage(request.messages),
      'stream': true,
    };

    if (request.modelSetting != null) {
      body['temperature'] = request.modelSetting!.temperature;
      body['top_p'] = request.modelSetting!.topP;
      body['frequency_penalty'] = request.modelSetting!.frequencyPenalty;
      body['presence_penalty'] = request.modelSetting!.presencePenalty;
      if (request.modelSetting!.maxTokens != null) {
        body['max_tokens'] = request.modelSetting!.maxTokens!;
      }
    }

    print("openai stream body: ${jsonEncode(body)}");

    try {
      _dio.options.responseType = ResponseType.stream;
      final response = await _dio.post(
        "$baseUrl/chat/completions",
        data: jsonEncode(body),
      );

      String buffer = '';
      await for (final chunk in response.data.stream) {
        final decodedChunk = utf8.decode(chunk);
        buffer += decodedChunk;

        // 处理可能的多行数据
        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);

          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

            try {
              final json = jsonDecode(jsonStr);

              // 检查 choices 数组是否为空
              if (json['choices'] == null || json['choices'].isEmpty) {
                continue;
              }

              final delta = json['choices'][0]['delta'];
              if (delta == null) continue;

              // 解析工具调用
              final toolCalls = delta['tool_calls']
                  ?.map<ToolCall>((t) => ToolCall(
                        id: t['id'] ?? '',
                        type: t['type'] ?? '',
                        function: FunctionCall(
                          name: t['function']?['name'] ?? '',
                          arguments: t['function']?['arguments'] ?? '{}',
                        ),
                      ))
                  ?.toList();

              // 只在有内容或工具调用时才yield响应
              if (delta['content'] != null || toolCalls != null) {
                yield LLMResponse(
                  content: delta['content'],
                  toolCalls: toolCalls,
                );
              }
            } catch (e) {
              Logger.root.severe('Failed to parse chunk: $jsonStr $e');
              continue;
            }
          }
        }
      }
    } catch (e) {
      throw await handleError(
          e, 'OpenAI', '$baseUrl/chat/completions', jsonEncode(body));
    }
  }

  @override
  Future<String> genTitle(List<ChatMessage> messages) async {
    final conversationText = messages.map((msg) {
      final role = msg.role == MessageRole.user ? "Human" : "Assistant";
      return "$role: ${msg.content}";
    }).join("\n");

    try {
      final prompt = ChatMessage(
        role: MessageRole.assistant,
        content:
            """You are a conversation title generator. Generate a concise title (max 20 characters) for the following conversation.
The title should summarize the main topic. Return only the title without any explanation or extra punctuation.

Conversation:
$conversationText""",
      );

      final response = await chatCompletion(CompletionRequest(
        model: "gpt-4o-mini",
        messages: [prompt],
      ));
      return response.content?.trim() ?? "New Chat";
    } catch (e, trace) {
      Logger.root.severe('OpenAI gen title error: $e, trace: $trace');
      return "New Chat";
    }
  }

  @override
  Future<List<String>> models() async {
    if (apiKey.isEmpty) {
      Logger.root.info('OpenAI API 密钥未设置，跳过模型列表获取');
      return [];
    }

    try {
      final response = await _dio.get("$baseUrl/models");

      final data = response.data;

      final models =
          (data['data'] as List).map((m) => m['id'].toString()).toList();

      return models;
    } catch (e, trace) {
      Logger.root.severe('获取模型列表失败: $e, trace: $trace');
      // 返回预定义的模型列表作为后备
      return [];
    }
  }
}

List<Map<String, dynamic>> chatMessageToOpenAIMessage(
    List<ChatMessage> messages) {
  return messages.map((message) {
    final json = <String, dynamic>{
      'role': message.role.value,
    };

    // 如果同时有文本内容和文件，需要使用数组格式
    if (message.content != null || message.files != null) {
      final List<Map<String, dynamic>> contentParts = [];

      // 添加文件内容
      if (message.files != null) {
        for (final file in message.files!) {
          if (isImageFile(file.fileType)) {
            contentParts.add({
              'type': 'image_url',
              'image_url': {
                "url": "data:${file.fileType};base64,${file.fileContent}",
              },
            });
          }
          if (isTextFile(file.fileType)) {
            contentParts.add({
              'type': 'text',
              'text': file.fileContent,
            });
          }
        }
      }

      // 添加文本内容
      if (message.content != null) {
        contentParts.add({
          'type': 'text',
          'text': message.content,
        });
      }

      // 如果只有一个文本内容且没有文件，使用简单字符串格式
      if (contentParts.length == 1 && message.files == null) {
        json['content'] = message.content;
      } else {
        json['content'] = contentParts;
      }
    }

    // 添加工具调用相关字段
    if (message.role == MessageRole.tool &&
        message.name != null &&
        message.toolCallId != null) {
      json['name'] = message.name!;
      json['tool_call_id'] = message.toolCallId!;
    }

    if (message.toolCalls != null) {
      json['tool_calls'] = message.toolCalls;
    }

    return json;
  }).toList();
}
