import 'package:dio/dio.dart';
import 'base_llm_client.dart';
import 'dart:convert';
import 'model.dart';
import 'package:logging/logging.dart';

class GeminiClient extends BaseLLMClient {
  final String apiKey;
  final String baseUrl;
  final Dio _dio;

  GeminiClient({
    required this.apiKey,
    String? baseUrl,
    Dio? dio,
  })  : baseUrl = (baseUrl == null || baseUrl.isEmpty)
            ? 'https://generativelanguage.googleapis.com/v1beta'
            : baseUrl,
        _dio = dio ??
            Dio(BaseOptions(
              headers: {
                'Content-Type': 'application/json',
              },
            ));

  @override
  Future<LLMResponse> chatCompletion(CompletionRequest request) async {
    final modelName = request.model;

    final body = {
      'contents': chatMessageToGeminiMessage(request.messages),
      if (request.modelSetting != null)
        'generationConfig': {
          'temperature': request.modelSetting!.temperature,
          'topP': request.modelSetting!.topP,
          if (request.modelSetting!.maxTokens != null)
            'maxOutputTokens': request.modelSetting!.maxTokens,
        }
    };

    try {
      final response = await _dio.post(
        "$baseUrl/models/$modelName:generateContent?key=$apiKey",
        data: jsonEncode(body),
      );

      // 确保响应数据是字符串并解析为 JSON
      String responseStr = '';
      if (response.data is String) {
        responseStr = response.data;
      } else if (response.data is ResponseBody) {
        responseStr = await utf8.decodeStream(response.data.stream);
      } else {
        responseStr = jsonEncode(response.data);
      }

      print('responseStr: $responseStr');

      dynamic jsonData = jsonDecode(responseStr);

      final candidates = jsonData['candidates'] as List;
      if (candidates.isEmpty) {
        throw Exception('No response from Gemini API');
      }

      final content = candidates[0]['content'];
      final text = content['parts'][0]['text'];

      return LLMResponse(
        content: text,
      );
    } catch (e) {
      throw await handleError(e, 'Gemini',
          '$baseUrl/models/$modelName:generateContent', jsonEncode(body));
    }
  }

  @override
  Stream<LLMResponse> chatStreamCompletion(CompletionRequest request) async* {
    final modelName = request.model;

    final Map<String, dynamic> body = {
      'contents': [...chatMessageToGeminiMessage(request.messages)],
    };

    if (request.modelSetting != null) {
      body['generationConfig'] = {
        'temperature': request.modelSetting!.temperature,
        'topP': request.modelSetting!.topP,
        if (request.modelSetting!.maxTokens != null)
          'maxOutputTokens': request.modelSetting!.maxTokens,
      };
    }

    try {
      _dio.options.responseType = ResponseType.stream;
      final response = await _dio.post(
        "$baseUrl/models/$modelName:streamGenerateContent?key=$apiKey&alt=sse",
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

          if (line.isEmpty) continue;

          if (!line.startsWith('data: ')) continue;

          try {
            final json =
                jsonDecode(line.substring(6)); // Remove 'data: ' prefix

            final candidates = json['candidates'] as List;
            if (candidates.isEmpty) continue;

            final content = candidates[0]['content'];
            final text = content['parts'][0]['text'];

            yield LLMResponse(
              content: text,
            );
          } catch (e) {
            Logger.root.severe('Failed to parse chunk: $line $e');
            continue;
          }
        }
      }
    } catch (e) {
      throw await handleError(e, 'Gemini',
          '$baseUrl/models/$modelName:streamGenerateContent', jsonEncode(body));
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
            """Generate a concise title (max 20 characters) for the following conversation.
The title should summarize the main topic. Return only the title without any explanation or extra punctuation.

Conversation:
$conversationText""",
      );

      final response = await chatCompletion(CompletionRequest(
        model: "gemini-2.0-flash",
        messages: [prompt],
      ));

      // 获取标题并进行处理
      String title = response.content?.trim() ?? "New Chat";
      if (title.length > 50) {
        title = title.substring(0, 50);
      }
      return title;
    } catch (e, trace) {
      Logger.root.severe('Gemini gen title error: $e, trace: $trace');
      return "New Chat";
    }
  }

  @override
  Future<List<String>> models() async {
    if (apiKey.isEmpty) {
      Logger.root.info('Gemini API key not set, skipping model list fetch');
      return [];
    }

    try {
      final response = await _dio.get("$baseUrl/models?key=$apiKey");
      final data = response.data;

      final models = (data['models'] as List)
          .map((m) => m['name'].toString().replaceAll('models/', ''))
          .where((name) => name.startsWith('gemini-'))
          .toList();

      return models;
    } catch (e, trace) {
      Logger.root.severe('Failed to get model list: $e, trace: $trace');
      return [];
    }
  }
}

List<Map<String, dynamic>> chatMessageToGeminiMessage(
    List<ChatMessage> messages) {
  return messages.map((message) {
    final parts = <Map<String, dynamic>>[];

    // Add text content
    if (message.content != null && message.content!.isNotEmpty) {
      parts.add({
        'text': message.content,
      });
    }

    // Add file content
    if (message.files != null) {
      for (final file in message.files!) {
        if (isImageFile(file.fileType)) {
          parts.add({
            'inlineData': {
              'mimeType': file.fileType,
              'data': file.fileContent,
            },
          });
        }
      }
    }

    // 确保至少有一个part
    if (parts.isEmpty) {
      parts.add({
        'text': ' ', // 添加一个空格作为默认文本
      });
    }

    return {
      'role': message.role == MessageRole.user ? 'user' : 'model',
      'parts': parts,
    };
  }).toList();
}

bool isImageFile(String mimeType) {
  return mimeType.startsWith('image/');
}
