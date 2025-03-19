import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../mcp/mcp.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:chatmcp/utils/platform.dart';
import '../mcp/client/mcp_client_interface.dart';

class McpServerProvider extends ChangeNotifier {
  static final McpServerProvider _instance = McpServerProvider._internal();
  factory McpServerProvider() => _instance;
  McpServerProvider._internal() {
    init();
  }

  static const _configFileName = 'mcp_server.json';

  Map<String, McpClient> _servers = {};

  Map<String, McpClient> get clients => _servers;

  // 判断当前平台是否支持 MCP Server
  bool get isSupported {
    return !Platform.isIOS && !Platform.isAndroid;
  }

  // 获取配置文件路径
  Future<String> get _configFilePath async {
    final directory = await getAppDir('ChatMcp');
    return '${directory.path}/$_configFileName';
  }

  // 检查并创建初始配置文件
  Future<void> _initConfigFile() async {
    final file = File(await _configFilePath);

    if (!await file.exists()) {
      // 从 assets 加载默认配置
      final defaultConfig =
          await rootBundle.loadString('assets/mcp_server.json');
      // 写入默认配置到配置文件
      await file.writeAsString(defaultConfig);
      Logger.root.info('已从 assets 初始化默认配置文件');
    }
  }

  // 读取服务器配置
  Future<Map<String, dynamic>> loadServers() async {
    try {
      await _initConfigFile();
      final file = File(await _configFilePath);
      final String contents = await file.readAsString();
      final Map<String, dynamic> data = json.decode(contents);
      if (data['mcpServers'] == null) {
        data['mcpServers'] = <String, dynamic>{};
      }
      return data;
    } catch (e, stackTrace) {
      Logger.root.severe('读取配置文件失败: $e, stackTrace: $stackTrace');
      return {'mcpServers': <String, dynamic>{}};
    }
  }

  // 保存服务器配置
  Future<void> saveServers(Map<String, dynamic> servers) async {
    try {
      final file = File(await _configFilePath);
      final prettyContents =
          const JsonEncoder.withIndent('  ').convert(servers);
      await file.writeAsString(prettyContents);
      // 保存后重新初始化客户端
      await _reinitializeClients();
    } catch (e, stackTrace) {
      Logger.root.severe('保存配置文件失败: $e, stackTrace: $stackTrace');
    }
  }

  // 重新初始化客户端
  Future<void> _reinitializeClients() async {
    // _servers.clear();
    await init();
    notifyListeners();
  }

  void addClient(String key, McpClient client) {
    _servers[key] = client;
    notifyListeners();
  }

  void removeClient(String key) {
    _servers.remove(key);
    notifyListeners();
  }

  McpClient? getClient(String key) {
    return _servers[key];
  }

  final Map<String, List<Map<String, dynamic>>> _tools = {};
  Map<String, List<Map<String, dynamic>>> get tools {
    return _tools;
  }

  bool loadingServerTools = false;

  Future<List<Map<String, dynamic>>> getServerTools(
      String serverName, McpClient client) async {
    final tools = <Map<String, dynamic>>[];
    final response = await client.sendToolList();
    final toolsList = response.toJson()['result']['tools'] as List<dynamic>;
    tools.addAll(toolsList.cast<Map<String, dynamic>>());
    return tools;
  }

  Future<void> init() async {
    try {
      // 先确保配置文件存在
      await _initConfigFile();

      final configFilePath = await _configFilePath;
      Logger.root.info('mcp_server path: $configFilePath');

      // 添加配置文件内容日志
      final configFile = File(configFilePath);
      final configContent = await configFile.readAsString();
      Logger.root.info('mcp_server config: $configContent');

      final ignoreServers = <String>[];
      for (var entry in clients.entries) {
        ignoreServers.add(entry.key);
      }

      Logger.root.info('mcp_server ignoreServers: $ignoreServers');

      _servers = await initializeAllMcpServers(configFilePath, ignoreServers);
      Logger.root.info('mcp_server count: ${_servers.length}');
      for (var entry in _servers.entries) {
        addClient(entry.key, entry.value);
      }

      notifyListeners();
    } catch (e, stackTrace) {
      Logger.root.severe('初始化 MCP 服务器失败: $e, stackTrace: $stackTrace');
      // 打印更详细的错误信息
      if (e is TypeError) {
        final configFile = File(await _configFilePath);
        final content = await configFile.readAsString();
        Logger.root.severe('配置文件解析错误，当前配置内容: $content');
      }
    }
  }

  Future<Map<String, McpClient>> initializeAllMcpServers(
      String configPath, List<String> ignoreServers) async {
    final file = File(configPath);
    final contents = await file.readAsString();

    final Map<String, dynamic> config =
        json.decode(contents) as Map<String, dynamic>? ?? {};

    final mcpServers = config['mcpServers'] as Map<String, dynamic>;

    final Map<String, McpClient> clients = {};

    for (var entry in mcpServers.entries) {
      if (ignoreServers.contains(entry.key)) {
        continue;
      }

      final serverName = entry.key;
      final serverConfig = entry.value as Map<String, dynamic>;

      try {
        // 创建异步任务并添加到列表
        final client = await initializeMcpServer(serverConfig);
        if (client != null) {
          clients[serverName] = client;
          loadingServerTools = true;
          notifyListeners();
          final tools = await getServerTools(serverName, client);
          _tools[serverName] = tools;
          loadingServerTools = false;
          notifyListeners();
        }
      } catch (e, stackTrace) {
        Logger.root
            .severe('初始化 MCP 服务器失败: $serverName, $e, stackTrace: $stackTrace');
      }
    }

    return clients;
  }

  String mcpServerMarket =
      "https://raw.githubusercontent.com/daodao97/chatmcp/refs/heads/main/assets/mcp_server_market.json";

  Future<Map<String, dynamic>> loadMarketServers() async {
    try {
      final dio = Dio();
      final response = await dio.get(mcpServerMarket);
      if (response.statusCode == 200) {
        Logger.root.info('加载市场服务器成功: ${response.data}');
        final Map<String, dynamic> jsonData = json.decode(response.data);

        final Map<String, dynamic> servers =
            jsonData['mcpServers'] as Map<String, dynamic>;

        var sseServers = <String, dynamic>{};

        // 针对移动端，只保留 command 以 http 开头的服务器
        if (Platform.isIOS || Platform.isAndroid) {
          for (var server in servers.entries) {
            if (server.value['command'] != null &&
                server.value['command'].toString().startsWith('http')) {
              sseServers[server.key] = server.value;
            }
          }
        } else {
          sseServers = servers;
        }

        return {
          'mcpServers': sseServers,
        };
      }
      throw Exception('加载市场服务器失败: ${response.statusCode}');
    } catch (e, stackTrace) {
      Logger.root.severe('加载市场服务器失败: $e, stackTrace: $stackTrace');
      throw Exception('加载市场服务器失败: $e');
    }
  }
}
