import 'package:dio/dio.dart';
import 'base_llm_client.dart';
import 'dart:convert';
import 'model.dart';
import 'package:logging/logging.dart';

class OllamaClient extends BaseLLMClient {
  final String baseUrl;
  final Dio _dio;

  OllamaClient({
    String? baseUrl,
    Dio? dio,
  })  : baseUrl = (baseUrl == null || baseUrl.isEmpty)
            ? 'http://localhost:11434'
            : baseUrl,
        _dio = dio ??
            Dio(BaseOptions(
              headers: {
                'Content-Type': 'application/json',
              },
            ));

  @override
  Future<List<String>> models() async {
    try {
      final response = await _dio.get("$baseUrl/api/tags");
      final data = response.data;
      final modelsList = data['models'] as List;
      return modelsList
          .map((model) => (model['name'] as String).split(':').first)
          .toList();
    } catch (e, trace) {
      Logger.root.severe('获取模型列表失败: $e, trace: $trace');
      return [];
    }
  }

  @override
  Future<String> genTitle(List<ChatMessage> messages) async {
    final conversationText = messages.map((msg) {
      final role = msg.role == MessageRole.user ? "Human" : "Assistant";
      return "$role: ${msg.content}";
    }).join("\n");

    final prompt = ChatMessage(
      role: MessageRole.user,
      content: """你是一个对话标题生成器。请为以下对话生成一个简洁的标题（最多20个字符）。
标题应该总结主要话题。只返回标题，不要添加任何解释或额外的标点符号。

对话内容:
$conversationText""",
    );

    try {
      final response = await chatCompletion(CompletionRequest(
        model: "llama3.2",
        messages: [prompt],
      ));
      return response.content?.trim() ?? "New Chat";
    } catch (e) {
      Logger.root.warning('生成标题失败: $e');
      return "New Chat";
    }
  }

  @override
  Future<LLMResponse> chatCompletion(CompletionRequest request) async {
    final messages = request.messages.map((m) {
      final role = m.role == MessageRole.user ? 'user' : 'assistant';
      return {
        'role': role,
        'content': m.content,
      };
    }).toList();

    final body = {
      'model': request.model,
      'messages': messages,
      'stream': false,
    };

    if (request.tools != null && request.tools!.isNotEmpty) {
      body['tools'] = request.tools!;
    }

    final bodyStr = jsonEncode(body);

    try {
      final response = await _dio.post(
        "$baseUrl/api/chat",
        data: bodyStr,
      );

      var jsonData = response.data;
      Logger.root.fine('Response data: ${jsonEncode(jsonData)}');
      final message = jsonData['message'];

      // 解析工具调用
      final toolCalls = message['tool_calls']
          ?.map<ToolCall>((t) => ToolCall(
                id: t['id'] ?? '',
                type: 'function',
                function: FunctionCall(
                  name: t['function']['name'],
                  arguments: jsonEncode(t['function']['arguments']),
                ),
              ))
          ?.toList();

      return LLMResponse(
        content: message['content'] ?? '',
        toolCalls: toolCalls,
      );
    } catch (e) {
      throw await handleError(e, 'Ollama', '$baseUrl/api/chat', bodyStr);
    }
  }

  @override
  Stream<LLMResponse> chatStreamCompletion(CompletionRequest request) async* {
    final messages = request.messages.map((m) {
      final role = m.role == MessageRole.user ? 'user' : 'assistant';
      return {
        'role': role,
        'content': m.content,
      };
    }).toList();

    final body = {
      'model': request.model,
      'messages': messages,
      'stream': true,
    };

    if (request.tools != null && request.tools!.isNotEmpty) {
      body['tools'] = request.tools!;
      body['tool_choice'] = 'auto';
    }

    try {
      _dio.options.responseType = ResponseType.stream;
      final response = await _dio.post(
        "$baseUrl/api/chat",
        data: jsonEncode(body),
      );

      String buffer = '';
      await for (final chunk in response.data.stream) {
        final decodedChunk = utf8.decode(chunk);
        buffer += decodedChunk;

        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);

          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

            try {
              final json = jsonDecode(jsonStr);
              final message = json['message'];
              if (message == null) continue;

              // 解析工具调用
              final toolCalls = message['tool_calls']
                  ?.map<ToolCall>((t) => ToolCall(
                        id: t['id'] ?? '',
                        type: 'function',
                        function: FunctionCall(
                          name: t['function']?['name'] ?? '',
                          arguments:
                              jsonEncode(t['function']?['arguments'] ?? {}),
                        ),
                      ))
                  ?.toList();

              // 只有当 content 不为空或有工具调用时才yield
              final content = message['content'];
              if (content?.isNotEmpty == true || toolCalls != null) {
                yield LLMResponse(
                  content: content ?? '',
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
          e, 'Ollama', '$baseUrl/api/chat', jsonEncode(body));
    }
  }
}
