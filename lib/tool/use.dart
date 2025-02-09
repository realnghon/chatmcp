import './tavily.dart';

Future<dynamic> useTool(String toolName, Map<String, dynamic> toolArgs) async {
  switch (toolName) {
    case 'web_search':
      return tavilySearch(toolArgs);
    default:
      throw Exception('Tool not found');
  }
}

Future<dynamic> tavilySearch(Map<String, dynamic> args) async {
  final client = TavilySearchClient();
  final request = TavilySearchRequest(query: args['query']);
  final response = await client.search(request); // 应该返回 response 而不是 request
  return response;
}
