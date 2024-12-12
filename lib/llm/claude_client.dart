import 'package:dio/dio.dart';
import 'base_llm_client.dart';
import 'model.dart';

class ClaudeClient extends BaseLLMClient {
  final String apiKey;
  String baseUrl = 'https://api.anthropic.com/v1/messages';
  final Dio _dio;

  ClaudeClient({required this.apiKey, required this.baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': apiKey,
                'anthropic-version': '2023-06-01',
              },
              responseType: ResponseType.stream,
            ));

  @override
  Future<LLMResponse> chatCompletion(CompletionRequest request) async {
    // Claude 特定的实现
    throw UnimplementedError();
  }

  @override
  Stream<LLMResponse> chatStreamCompletion(CompletionRequest request) async* {
    // Claude 特定的实现
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> checkToolCall(
    String content,
    Map<String, List<Map<String, dynamic>>> toolsResponse,
  ) async {
    // Claude 特定的实现
    throw UnimplementedError();
  }

  @override
  Future<String> genTitle(List<ChatMessage> messages) async {
    return "New Chat";
  }
}
