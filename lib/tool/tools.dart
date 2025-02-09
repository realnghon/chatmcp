export 'package:ChatMcp/tool/use.dart';
import 'package:ChatMcp/provider/provider_manager.dart';

Future<List<Map<String, dynamic>>> getTools() async {
  final tools = ProviderManager.settingsProvider.apiSettings;
  return _localTools
      .where((tool) {
        if (tool['name'] == 'web_search' && !tools.containsKey('tavily')) {
          return false;
        }
        return true;
      })
      .map((tool) => tool)
      .toList();
}

List<Map<String, dynamic>> _localTools = [
  {
    'name': 'web_search',
    'description': '在互联网上搜索以获取最新信息',
    'inputSchema': {
      "description": "Parameters for web search",
      "properties": {
        "query": {
          "type": "string",
          "description": "The query to search for",
        },
        "search_depth": {
          "type": "string",
          "description": "Search depth",
          "default": "basic",
          "enum": ["basic", "advanced"],
        },
        "max_results": {
          "type": "integer",
          "description": " The maximum number of results to return",
          "default": 10,
          "minimum": 1,
          "maximum": 20,
        },
      },
      "required": ["query"],
      "type": "object",
    },
  },
];
