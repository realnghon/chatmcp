import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import './models/server.dart';
import './client/mcp_client_interface.dart';
import './stdio/stdio_client.dart';
import './sse/sse_client.dart';

Future<McpClient?> initializeMcpServer(
    Map<String, dynamic> mcpServerConfig) async {
  // 获取服务器配置

  final serverConfig = ServerConfig.fromJson(mcpServerConfig);

  // 根据配置创建相应的客户端
  McpClient mcpClient;
  if (serverConfig.command.startsWith('http')) {
    mcpClient = SSEClient(serverConfig: serverConfig);
  } else {
    mcpClient = StdioClient(serverConfig: serverConfig);
  }

  // 初始化客户端
  await mcpClient.initialize();
  // 等待10秒
  await Future.delayed(const Duration(seconds: 10));
  final initResponse = await mcpClient.sendInitialize();
  Logger.root.info('初始化响应: $initResponse');

  final toolListResponse = await mcpClient.sendToolList();
  Logger.root.info('工具列表响应: $toolListResponse');
  return mcpClient;
}

Future<bool> verifyMcpServer(Map<String, dynamic> mcpServerConfig) async {
  final serverConfig = ServerConfig.fromJson(mcpServerConfig);
  final mcpClient = serverConfig.command.startsWith('http')
      ? SSEClient(serverConfig: serverConfig)
      : StdioClient(serverConfig: serverConfig);

  try {
    await mcpClient.sendInitialize();
    return true;
  } catch (e) {
    return false;
  }
}
