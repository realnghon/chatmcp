import 'package:chatmcp/mcp/models/json_rpc_message.dart';

// 定义 JSON-RPC 响应类
class JsonRpcResponse {
  final String jsonrpc;
  final dynamic result;
  final Map<String, dynamic>? error;
  final dynamic id;

  JsonRpcResponse({
    required this.jsonrpc,
    this.result,
    this.error,
    required this.id,
  });

  factory JsonRpcResponse.fromJson(Map<String, dynamic> json) {
    return JsonRpcResponse(
      jsonrpc: json['jsonrpc'] ?? '2.0',
      id: json['id'],
      result: json['result'],
      error: json['error'] != null
          ? Map<String, dynamic>.from(json['error'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'jsonrpc': jsonrpc,
      'id': id,
    };
    // 根据 JSON-RPC 规范，result 和 error 是互斥的
    if (error != null) {
      data['error'] = error;
    } else {
      // 即使 result 是 null 或空 map，也应该包含它 (如果 error 不存在)
      data['result'] = result;
    }
    return data;
  }
}

// 处理请求的函数
JsonRpcResponse handleRequest(JSONRPCMessage request) {
  dynamic result;
  Map<String, dynamic>? error;

  try {
    switch (request.method) {
      case 'initialize':
        result = {
          'protocolVersion': '1.0',
          'serverInfo': {
            'name': 'mock-server-dart',
            'version': '1.0.0',
          },
          'capabilities': {
            'prompts': {
              'listChanged': true,
            },
            'resources': {
              'listChanged': true,
              'subscribe': true,
            },
            'tools': {
              'listChanged': true,
            },
          },
        };
        break;
      case 'ping':
        result = {}; // 空对象
        break;
      case 'resources/list':
        result = {
          'resources': [
            {
              'name': 'test-resource',
              'uri': 'test://resource',
            },
          ],
        };
        break;
      case 'resources/read':
        // 实际实现中应从 request.params 获取 URI
        // final uri = request.params?['uri'];
        // if (uri == null) throw ArgumentError('Missing parameter: uri');
        // ... 根据 uri 读取内容 ...
        result = {
          'contents': [
            {
              'text': 'test content',
              'uri': 'test://resource', // 使用模拟 URI
            },
          ],
        };
        break;
      case 'resources/subscribe':
      case 'resources/unsubscribe':
        // 实际实现中应处理订阅/取消订阅逻辑
        // final uri = request.params?['uri'];
        // if (uri == null) throw ArgumentError('Missing parameter: uri');
        result = {}; // 成功时返回空对象
        break;
      case 'prompts/list':
        result = {
          'prompts': [
            {
              'name': 'test-prompt',
            },
          ],
        };
        break;
      case 'prompts/get':
        // 实际实现中应从 request.params 获取 prompt 名称/ID
        // final promptName = request.params?['name'];
        result = {
          'messages': [
            {
              'role': 'assistant',
              'content': {
                'type': 'text',
                'text': 'test message',
              },
            },
          ],
        };
        break;
      case 'tools/list':
        result = {
          'tools': [
            {
              'name': 'test-tool',
              'inputSchema': {
                'type': 'object',
                // 'properties': { ... } // 可以添加 schema 定义
              },
              // 'description': 'A test tool' // 可选描述
            },
          ],
        };
        break;
      case 'tools/call':
        // 实际实现中应从 request.params 获取工具名称和输入
        // final toolName = request.params?['tool'];
        // final input = request.params?['input'];
        // if (toolName == null) throw ArgumentError('Missing parameter: tool');
        // ... 执行工具调用 ...
        result = {
          'content': [
            {
              'type': 'text',
              'text': 'tool result',
            },
          ],
        };
        break;
      case 'logging/setLevel':
        // 实际实现中应从 request.params 获取日志级别
        // final level = request.params?['level'];
        // if (level == null) throw ArgumentError('Missing parameter: level');
        result = {}; // 成功时返回空对象
        break;
      case 'completion/complete':
        // 实际实现中应从 request.params 获取补全所需信息
        // final context = request.params?['context'];
        result = {
          'completion': {
            'values': ['test completion'],
          },
        };
        break;
      default:
        error = {
          'code': -32601, // Method not found
          'message': 'Method not found: ${request.method}',
        };
    }
  } catch (e, stackTrace) {
    // 捕获处理过程中的任何异常，并将其格式化为 JSON-RPC 错误
    print('Error handling request: $e');
    print('Stack trace:\n$stackTrace');
    error = {
      'code': -32603, // Internal error
      'message': 'Internal server error: ${e.toString()}',
      // 'data': stackTrace.toString(), // 可选：包含调试信息
    };
    result = null; // 确保出错时 result 为 null
  }

  return JsonRpcResponse(
    jsonrpc: '2.0',
    id: request.id,
    result: result,
    error: error,
  );
}

// 示例用法 (可选, 通常放在单独的测试文件或 main 文件中)
/*
void main() {
  // 模拟一个请求
  final requestJson = {
    'jsonrpc': '2.0',
    'method': 'initialize',
    'id': 1,
  };
  final request = JsonRpcRequest.fromJson(requestJson);

  // 处理请求
  final response = handleRequest(request);

  // 打印响应 (转换为 JSON 字符串)
  print(jsonEncode(response.toJson()));

   // 模拟另一个请求
  final pingRequestJson = {
    'jsonrpc': '2.0',
    'method': 'ping',
    'id': 2,
  };
  final pingRequest = JsonRpcRequest.fromJson(pingRequestJson);
  final pingResponse = handleRequest(pingRequest);
  print(jsonEncode(pingResponse.toJson()));

   // 模拟错误请求
  final errorRequestJson = {
    'jsonrpc': '2.0',
    'method': 'unknown_method',
    'id': 3,
  };
  final errorRequest = JsonRpcRequest.fromJson(errorRequestJson);
  final errorResponse = handleRequest(errorRequest);
  print(jsonEncode(errorResponse.toJson()));

  // 模拟带参数的请求 (需要取消 handleRequest 中相应注释)
  // final resourceReadRequestJson = {
  //   'jsonrpc': '2.0',
  //   'method': 'resources/read',
  //   'params': {'uri': 'specific://resource'},
  //   'id': 4,
  // };
  // final resourceReadRequest = JsonRpcRequest.fromJson(resourceReadRequestJson);
  // final resourceReadResponse = handleRequest(resourceReadRequest);
  // print(jsonEncode(resourceReadResponse.toJson()));

   // 模拟导致内部错误的请求 (例如，缺少参数且未正确处理)
   final badParamRequestJson = {
     'jsonrpc': '2.0',
     'method': 'resources/read', // 假设此方法需要 uri 参数
     // 'params': {}, // 故意不传参数
     'id': 5,
   };
    try {
      final badParamRequest = JsonRpcRequest.fromJson(badParamRequestJson);
      final badParamResponse = handleRequest(badParamRequest);
      print(jsonEncode(badParamResponse.toJson()));
    } catch (e) {
      print('Error creating/handling request: $e');
      // 在实际应用中，fromJson 或 handleRequest 内部的错误处理会捕获这个
    }


}
*/
