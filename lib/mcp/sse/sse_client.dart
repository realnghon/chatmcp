import 'package:chatmcp/mcp/stdio/stdio_client.dart';
import 'package:synchronized/synchronized.dart';

import '../client/mcp_client_interface.dart';
import '../models/json_rpc_message.dart';
import '../models/server.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class SSEClient implements McpClient {
  final ServerConfig _serverConfig;
  final _pendingRequests = <String, Completer<JSONRPCMessage>>{};
  final _processStateController = StreamController<ProcessState>.broadcast();
  Stream<ProcessState> get processStateStream => _processStateController.stream;

  StreamSubscription? _sseSubscription;
  final _writeLock = Lock();
  String? _messageEndpoint;

  bool _isConnecting = false;
  bool _disposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  Timer? _reconnectTimer;

  SSEClient({required ServerConfig serverConfig})
      : _serverConfig = serverConfig;

  @override
  ServerConfig get serverConfig => _serverConfig;

  void _handleMessage(JSONRPCMessage message) {
    if (message.id != null && _pendingRequests.containsKey(message.id)) {
      final completer = _pendingRequests.remove(message.id);
      completer?.complete(message);
    }
  }

  @override
  Future<void> initialize() async {
    _reconnectAttempts = 0;
    await _connect();
  }

  Future<void> _connect() async {
    if (_isConnecting || _disposed) return;

    _isConnecting = true;
    try {
      Logger.root.info('开始 SSE 连接: ${serverConfig.command}');
      _processStateController.add(const ProcessState.starting());

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(serverConfig.command));
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');
      request.headers.set('Connection', 'keep-alive');

      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('SSE 连接失败: ${response.statusCode}');
      }

      _reconnectAttempts = 0;

      _sseSubscription = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (String line) {
          print("SSEClient: $line");
          if (line.startsWith('event: endpoint')) {
            return;
          }
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (_messageEndpoint == null) {
              final baseUrl =
                  Uri.parse(serverConfig.command).replace(path: '').toString();
              _messageEndpoint =
                  data.startsWith("http") ? data : baseUrl + data;
              Logger.root.info('收到消息端点: $_messageEndpoint');
              _processStateController.add(const ProcessState.running());
            } else {
              try {
                final jsonData = jsonDecode(data);
                final message = JSONRPCMessage.fromJson(jsonData);
                _handleMessage(message);
              } catch (e, stack) {
                Logger.root.severe('解析服务器消息失败: $e\n$stack');
              }
            }
          }
        },
        onError: (error) {
          Logger.root.severe('SSE 连接错误: $error');
          _processStateController
              .add(ProcessState.error(error, StackTrace.current));
          _scheduleReconnect();
        },
        onDone: () {
          Logger.root.info('SSE 连接已关闭');
          _processStateController.add(const ProcessState.exited(0));
          _scheduleReconnect();
        },
      );
    } catch (e, stack) {
      Logger.root.severe('SSE 连接失败: $e\n$stack');
      _processStateController.add(ProcessState.error(e, stack));
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _isConnecting || _reconnectTimer != null) return;

    _reconnectAttempts++;
    if (_reconnectAttempts > _maxReconnectAttempts) {
      Logger.root.severe('达到最大重连尝试次数 ($_maxReconnectAttempts)，停止重连');
      return;
    }

    final delay = _initialReconnectDelay * (1 << (_reconnectAttempts - 1));
    Logger.root.info('计划在 ${delay.inSeconds} 秒后进行第 $_reconnectAttempts 次重连尝试');

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _connect();
    });
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _sseSubscription?.cancel();
    await _processStateController.close();
  }

  Future<void> _sendHttpPost(Map<String, dynamic> data) async {
    if (_messageEndpoint == null) {
      throw StateError('消息端点尚未初始化 ${jsonEncode(data)}');
    }

    await _writeLock.synchronized(() async {
      try {
        await Dio().post(
          _messageEndpoint!,
          data: jsonEncode(data),
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      } catch (e) {
        Logger.root.severe('发送 HTTP POST 失败: $e');
        rethrow;
      }
    });
  }

  @override
  Future<JSONRPCMessage> sendMessage(JSONRPCMessage message) async {
    if (message.id == null) {
      throw ArgumentError('消息必须包含 ID');
    }

    final completer = Completer<JSONRPCMessage>();
    _pendingRequests[message.id!] = completer;

    try {
      await _sendHttpPost(message.toJson());
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _pendingRequests.remove(message.id);
          throw TimeoutException('请求超时: ${message.id}');
        },
      );
    } catch (e) {
      _pendingRequests.remove(message.id);
      rethrow;
    }
  }

  @override
  Future<JSONRPCMessage> sendInitialize() async {
    final initMessage =
        JSONRPCMessage(id: 'init-1', method: 'initialize', params: {
      'protocolVersion': '2024-11-05',
      'capabilities': {
        'roots': {'listChanged': true},
        'sampling': {}
      },
      'clientInfo': {'name': 'DartMCPClient', 'version': '1.0.0'}
    });

    Logger.root.info('初始化请求: ${jsonEncode(initMessage.toString())}');

    final initResponse = await sendMessage(initMessage);
    Logger.root.info('初始化请求响应: $initResponse');

    final notifyMessage = JSONRPCMessage(method: 'initialized', params: {});

    await _sendHttpPost(notifyMessage.toJson());
    return initResponse;
  }

  @override
  Future<JSONRPCMessage> sendPing() async {
    final message = JSONRPCMessage(id: 'ping-1', method: 'ping');
    return sendMessage(message);
  }

  @override
  Future<JSONRPCMessage> sendToolList() async {
    final message = JSONRPCMessage(id: 'tool-list-1', method: 'tools/list');
    return sendMessage(message);
  }

  @override
  Future<JSONRPCMessage> sendToolCall({
    required String name,
    required Map<String, dynamic> arguments,
    String? id,
  }) async {
    final message = JSONRPCMessage(
      method: 'tools/call',
      params: {
        'name': name,
        'arguments': arguments,
        '_meta': {'progressToken': 0},
      },
      id: id ?? 'tool-call-${DateTime.now().millisecondsSinceEpoch}',
    );

    return sendMessage(message);
  }
}
