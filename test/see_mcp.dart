import 'package:ChatMcp/mcp/models/server.dart';
import 'package:ChatMcp/mcp/sse/sse_client.dart';
import 'package:test/test.dart';

void main() {
  group('SSEClient 集成测试', () {
    late SSEClient sseClient;

    setUp(() {
      final serverConfig = ServerConfig(
        command: 'http://localhost:8080/sse', // 请确保这是你的实际服务器地址
        args: [],
      );

      sseClient = SSEClient(serverConfig: serverConfig);
    });

    test('完整流程测试', () async {
      // 1. 初始化连接
      await sseClient.initialize();

      // 2. 发送初始化请求
      final initResponse = await sseClient.sendInitialize();
      expect(initResponse.id, 'init-1');
      expect(initResponse.error, isNull);

      // 3. 测试 ping
      final pingResponse = await sseClient.sendPing();
      expect(pingResponse.error, isNull);

      // 4. 获取工具列表
      final toolListResponse = await sseClient.sendToolList();
      print(toolListResponse);
      expect(toolListResponse.error, isNull);
      expect(toolListResponse.result, isNotNull);

      // 5. 测试工具调用
      final toolCallResponse = await sseClient.sendToolCall(
        name: 'sample.hello',
        arguments: {'message': 'Hello, World!'},
      );
      expect(toolCallResponse.error, isNull);
      expect(toolCallResponse.result, isNotNull);
    });

    test('进程状态流测试', () async {
      // 监听进程状态变化
      sseClient.processStateStream.listen((state) {
        print(state);
      });

      await sseClient.initialize();
      // 等待一段时间以观察状态变化
      await Future.delayed(const Duration(seconds: 2));
    });

    tearDown(() async {
      await sseClient.dispose();
    });
  });
}
