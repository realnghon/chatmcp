import 'package:dio/dio.dart';
import 'base_llm_client.dart';
import 'dart:convert';
import 'model.dart';
import 'package:logging/logging.dart';
import './openai_client.dart';
import 'package:chatmcp/provider/provider_manager.dart';

class DeepSeekClient extends BaseLLMClient {
  final String apiKey;
  String baseUrl;
  final Dio _dio;

  DeepSeekClient({
    required this.apiKey,
    String? baseUrl,
    Dio? dio,
  })  : baseUrl = (baseUrl == null || baseUrl.isEmpty)
            ? 'https://api.deepseek.com/v1'
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
      'messages': chatMessageToDeepSeekMessage(request.messages),
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
          e, 'DeepSeek', '$baseUrl/chat/completions', jsonEncode(body));
    }
  }

  @override
  Stream<LLMResponse> chatStreamCompletion(CompletionRequest request) async* {
    final body = {
      'model': request.model,
      'messages': chatMessageToDeepSeekMessage(request.messages),
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

    try {
      Logger.root.info('deepseek request chat stream completion');
      _dio.options.responseType = ResponseType.stream;
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: jsonEncode(body),
      );

      Logger.root.info('deepseek start stream response');
      String buffer = '';
      bool reasoningContentStart = false;
      bool reasoningContentEnd = false;
      bool reasoningStyle = false;
      await for (final chunk in response.data.stream) {
        final decodedChunk = utf8.decode(chunk);
        buffer += decodedChunk;

        // 处理可能的多行数据
        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim();
          Logger.root.info('deepseek stream response line: $line');
          buffer = buffer.substring(index + 1);

          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

            try {
              final json = jsonDecode(jsonStr);

              // 检查 choices 数组是否为空
              if (json['choices'] == null ||
                  json['choices'].isEmpty ||
                  json['choices'].length < 1) {
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

              final reasoningContent =
                  delta != null ? (delta['reasoning_content'] ?? '') : '';

              if (reasoningContent.isNotEmpty) {
                reasoningStyle = true;
                if (!reasoningContentStart) {
                  reasoningContentStart = true;
                  yield LLMResponse(
                    content:
                        '<think start-time="${DateTime.now().toIso8601String()}">$reasoningContent',
                    toolCalls: toolCalls,
                  );
                } else {
                  yield LLMResponse(
                    content: reasoningContent,
                    toolCalls: toolCalls,
                  );
                }
              }

              if (reasoningStyle) {
                final content = delta != null ? (delta['content'] ?? '') : '';
                if (content.isNotEmpty) {
                  if (!reasoningContentEnd) {
                    reasoningContentEnd = true;
                    yield LLMResponse(
                      content:
                          '</think end-time="${DateTime.now().toIso8601String()}">$content',
                      toolCalls: toolCalls,
                    );
                  } else {
                    yield LLMResponse(
                      content: content,
                      toolCalls: toolCalls,
                    );
                  }
                }
              } else {
                // 只在有内容或工具调用时才yield响应
                if (delta != null && delta['content'] != null) {
                  String content =
                      delta != null ? (delta['content'] ?? '') : '';
                  if (content.isNotEmpty && content.contains('<think>')) {
                    content = content.replaceAll('<think>',
                        '<think start-time="${DateTime.now().toIso8601String()}">');
                  }
                  if (content.isNotEmpty && content.contains('</think>')) {
                    content = content.replaceAll('</think>',
                        '</think end-time="${DateTime.now().toIso8601String()}">');
                  }

                  yield LLMResponse(
                    content: content,
                    toolCalls: toolCalls,
                  );
                }
              }
            } catch (e, trace) {
              Logger.root.severe(
                  'Failed to parse chunk: $jsonStr, error: $e, trace: $trace');
              continue;
            }
          }
        }
      }
    } catch (e, trace) {
      Logger.root.severe('DeepSeek stream completion error: $e, trace: $trace');
      throw await handleError(
          e, 'DeepSeek', '$baseUrl/chat/completions', jsonEncode(body));
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

      final models = ProviderManager.chatModelProvider.getModels();
      String modelName = "deepseek-chat";
      if (models.any((m) => m.name == "deepseek-v3")) {
        modelName = "deepseek-v3";
      }

      final response = await chatCompletion(CompletionRequest(
        model: modelName,
        messages: [prompt],
      ));
      return response.content?.trim() ?? "New Chat";
    } catch (e, trace) {
      Logger.root.severe('DeepSeek gen title error: $e, trace: $trace');
      return "New Chat";
    }
  }

  @override
  Future<List<String>> models() async {
    if (apiKey.isEmpty) {
      Logger.root.info('DeepSeek API 密钥未设置，跳过模型列表获取');
      return [];
    }

    try {
      final response = await _dio.get("$baseUrl/models");

      final data = response.data;

      final models = (data['data'] as List)
          .map((m) => m['id'].toString())
          .where((id) => id.contains('deepseek'))
          .toList();

      return models;
    } catch (e, trace) {
      Logger.root.severe('获取模型列表失败: $e, trace: $trace');
      // 返回预定义的模型列表作为后备
      return [];
    }
  }
}

List<Map<String, dynamic>> chatMessageToDeepSeekMessage(
    List<ChatMessage> messages) {
  return chatMessageToOpenAIMessage(messages);
}
