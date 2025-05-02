import 'package:logging/logging.dart';

import '../inmemory/memory_server.dart';
import '../models/json_rpc_message.dart';

class MathServer extends MemoryServer {
  MathServer() : super(name: 'math-server') {
    addTool(Tool(
      name: 'add',
      description: 'Add two numbers',
      inputSchema: ToolInput(
        type: 'object',
        description: 'Add two numbers',
        properties: [
          Property(name: 'a', type: ToolInputType.integer),
          Property(name: 'b', type: ToolInputType.integer),
        ],
        required: ['a', 'b'],
      ),
    ));
  }

  @override
  Map<String, dynamic> onToolCall(JSONRPCMessage message) {
    String name = message.params?['name'];
    Map<String, dynamic> arguments = message.params?['arguments'];
    Logger.root
        .fine('memory_server onToolCall name: $name arguments: $arguments');
    switch (name) {
      case 'add':
        return {
          'result':
              add(castToNumber(arguments['a']), castToNumber(arguments['b']))
        };
      default:
        return {'result': 'unknown tool'};
    }
  }

  int add(int a, int b) {
    return a + b;
  }
}

castToNumber(dynamic value) {
  if (value is int) {
    return value;
  }
  return num.tryParse(value);
}
