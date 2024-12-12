import 'package:dio/dio.dart';
import 'base_llm_client.dart';
import 'dart:convert';
import 'model.dart';
import 'package:logging/logging.dart';

var models = [
  Model(
    name: 'gpt-4o-mini',
    label: 'GPT-4o-mini',
  ),
  Model(
    name: 'gpt-4o',
    label: 'GPT-4o',
  ),
  Model(
    name: 'gpt-3.5-turbo',
    label: 'GPT-3.5',
  ),
  Model(
    name: 'gpt-4',
    label: 'GPT-4',
  ),
];

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
              responseType: ResponseType.stream,
            ));

  @override
  Future<LLMResponse> chatCompletion(CompletionRequest request) async {
    final body = {
      'model': 'gpt-4o-mini',
      'messages': request.messages.map((m) => m.toJson()).toList(),
    };

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

      // 处理流数据
      final buffer = StringBuffer();

      await for (final chunk in response.data.stream) {
        buffer.write(utf8.decode(chunk));
      }

      final responseBody = buffer.toString();
      final json = jsonDecode(responseBody);

      final message = json['choices'][0]['message'];

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
      final tips =
          "call openai chatCompletion failed: endpoint: $baseUrl/chat/completions body: $body $e";
      Logger.root.severe(tips);
      throw Exception(tips);
    }
  }

  @override
  Stream<LLMResponse> chatStreamCompletion(CompletionRequest request) async* {
    final body = {
      'model': request.model,
      'messages': request.messages.map((m) => m.toJson()).toList(),
      'stream': true,
    };

    try {
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
      throw Exception(
          "call openai chatStreamCompletion failed: endpoint: $baseUrl/chat/completions body: $body $e");
    }
  }

  @override
  Future<String> genTitle(List<ChatMessage> messages) async {
    final conversationText = messages.map((msg) {
      final role = msg.role == MessageRole.user ? "Human" : "Assistant";
      return "$role: ${msg.content}";
    }).join("\n");

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
  }
}
