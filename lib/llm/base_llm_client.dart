import 'model.dart';
import 'utils.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

abstract class BaseLLMClient {
  Future<LLMResponse> chatCompletion(CompletionRequest request);

  Stream<LLMResponse> chatStreamCompletion(CompletionRequest request);

  Future<Map<String, dynamic>> checkToolCall(
    String content,
    Map<String, List<Map<String, dynamic>>> toolsResponse,
  ) async {
    final openaiTools = convertToOpenAITools(toolsResponse);

    try {
      final response = await chatCompletion(
        CompletionRequest(
          model: ProviderManager.chatModelProvider.currentModel.name,
          messages: [ChatMessage(role: MessageRole.user, content: content)],
          tools: openaiTools,
        ),
      );

      if (!response.needToolCall) {
        return {
          'need_tool_call': false,
          'content': response.content,
        };
      }

      // 返回工具调用详情
      return {
        'need_tool_call': true,
        'content': response.content,
        'tool_calls': response.toolCalls
            ?.map((call) => {
                  'id': call.id,
                  'name': call.function.name,
                  'arguments': call.function.parsedArguments,
                })
            .toList(),
      };
    } catch (e) {
      rethrow; // 重新抛出异常，让外层处理
    }
  }

  Future<LLMException> handleError(
      dynamic e, String name, String endpoint, String bodyStr) async {
    if (e is DioException && e.response != null) {
      // 获取响应内容
      var responseData = e.response?.data;
      if (responseData is ResponseBody) {
        responseData = await utf8.decodeStream(responseData.stream);
      }

      return LLMException(
        name: name,
        endpoint: endpoint,
        requestBody: bodyStr,
        statusCode: e.response?.statusCode,
        responseData: responseData,
        originalError: e,
      );
    } else {
      return LLMException(
        name: name,
        endpoint: endpoint,
        requestBody: bodyStr,
        originalError: e,
      );
    }
  }

  Future<String> genTitle(List<ChatMessage> messages);

  Future<List<String>> models();
}

class LLMException implements Exception {
  final String name;
  final String endpoint;
  final String requestBody;
  final int? statusCode;
  final dynamic responseData;
  final dynamic originalError;

  LLMException({
    required this.name,
    required this.endpoint,
    required this.requestBody,
    this.statusCode,
    this.responseData,
    this.originalError,
  });

  @override
  String toString() {
    return '''
$name API 调用失败
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
接口地址: $endpoint
${statusCode != null ? '状态码: $statusCode\n' : ''}请求内容: $requestBody
${responseData != null ? '响应内容: $responseData\n' : ''}错误信息: $originalError
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''';
  }
}
