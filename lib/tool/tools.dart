export 'package:chatmcp/tool/use.dart';
import 'package:chatmcp/provider/provider_manager.dart';

Future<List<Map<String, dynamic>>> getTools() async {
  final tools = ProviderManager.settingsProvider.apiSettings;
  return _localTools
      .where((tool) {
        if (tool['name'] == 'web_search' && !tools.containsKey('tavily')) {
          return false;
        }
        // if (tool['name'] == 'generate_image') {
        //   return false;
        // }
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
  {
    'name': 'generate_image',
    'description': '使用 DALL-E 3 生成图片',
    'inputSchema': {
      "description": "Parameters for image generation",
      "properties": {
        "prompt": {
          "type": "string",
          "description": "图片生成提示词",
        },
        "size": {
          "type": "string",
          "description": "图片尺寸",
          "default": "1024x1024",
          "enum": ["1024x1024", "1024x1792", "1792x1024"],
        },
      },
      "required": ["prompt"],
      "type": "object",
    },
  },
  // {
  //   'name': 'generate_artifact',
  //   'description':
  //       '支持生成多种非纯文本内容，例如图片、图表、流程图、结构化文件（如代码、配置文件、表格、列表等），以及其他可视化或结构化输出',
  //   'inputSchema': {
  //     "description": "Parameters for generate artifact",
  //     "type": "object",
  //     "properties": {
  //       "name": {"type": "string", "description": "产物名称，用于标识输出内容"},
  //       "artifact_type": {
  //         "type": "string",
  //         "description": "产物类型（如图片、图表、流程图、代码、配置文件、表格、列表等）",
  //         "enum": ["image", "chart", "flowchart", "table", "list", "other"]
  //       },
  //       "content_brief": {"type": "string", "description": "生成内容的简要描述或需求说明"},
  //       "output_format": {
  //         "type": "string",
  //         "description": "输出格式（如 Markdown、SVG、PNG、纯文本等）"
  //       }
  //     },
  //     "required": ["name", "artifact_type"]
  //   },
  // },
];
