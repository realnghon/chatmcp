import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatmcp/provider/mcp_server_provider.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:chatmcp/provider/serve_state_provider.dart';
import 'package:flutter_switch/flutter_switch.dart';

class McpTools extends StatefulWidget {
  const McpTools({super.key});

  @override
  State<McpTools> createState() => _McpToolsState();
}

class _McpToolsState extends State<McpTools> {
  List<String>? _cachedServers;
  bool _isLoading = true;
  String? _error;

  // 服务器状态提供者
  final ServerStateProvider _stateProvider = ServerStateProvider();

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadServers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<McpServerProvider>(context, listen: false);
      final servers = await provider.mcpServers;

      // 更新服务器列表
      setState(() {
        _cachedServers = servers;
        _isLoading = false;
      });

      // 同步服务器状态
      _stateProvider.syncFromProvider(provider, servers);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // 处理服务器的状态切换
  Future<void> _handleServerToggle(
      BuildContext context, String serverName, bool newValue) async {
    final provider = Provider.of<McpServerProvider>(context, listen: false);

    // 更新启用状态
    _stateProvider.setEnabled(serverName, newValue);

    // 更新Provider中的状态
    provider.toggleToolCategory(serverName, newValue);

    // 如果新状态为true且服务器未运行，则启动服务器
    if (newValue && !provider.mcpServerIsRunning(serverName)) {
      // 设置启动中状态
      _stateProvider.setStarting(serverName, true);

      try {
        await provider.startMcpServer(serverName);
        // 更新运行状态
        _stateProvider.setRunning(serverName, true);
      } catch (e) {
        // 启动失败，更新状态
        _stateProvider.setRunning(serverName, false);
        _stateProvider.setStarting(serverName, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    return Consumer<McpServerProvider>(
      builder: (context, mcpServerProvider, child) {
        // 监听变化并同步状态
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cachedServers != null) {
            _stateProvider.syncFromProvider(mcpServerProvider, _cachedServers!);
          }
        });

        return PopupMenuButton<void>(
          tooltip: t.tool,
          offset: const Offset(0, 8),
          position: PopupMenuPosition.under,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 400,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onOpened: () {
            // 每次打开菜单时刷新服务器列表
            _loadServers();
          },
          itemBuilder: (context) {
            // 使用服务器列表构建菜单项
            return _buildMenuItems(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 使用 FutureBuilder 处理异步的 mcpServerCount
                FutureBuilder<int>(
                  future: mcpServerProvider.mcpServerCount,
                  builder: (context, snapshot) {
                    String countText = '...';
                    if (snapshot.hasData) {
                      countText = snapshot.data.toString();
                    } else if (snapshot.hasError) {
                      countText = 'Error';
                    }
                    return Text('Servers: $countText');
                  },
                ),
                const SizedBox(width: 4),
                Icon(
                  mcpServerProvider.loadingServerTools
                      ? CupertinoIcons.clock
                      : Icons.expand_more,
                  size: 18,
                  color: Theme.of(context).iconTheme.color,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PopupMenuEntry<void>> _buildMenuItems(BuildContext context) {
    final McpServerProvider provider =
        Provider.of<McpServerProvider>(context, listen: false);
    final List<PopupMenuEntry<void>> menuItems = [];

    // 处理加载状态
    if (_isLoading) {
      return [
        const PopupMenuItem<void>(
          enabled: false,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        )
      ];
    }

    // 处理错误状态
    if (_error != null) {
      return [
        PopupMenuItem<void>(
          enabled: false,
          child: Text('加载出错: $_error',
              style: Theme.of(context).textTheme.bodyMedium),
        )
      ];
    }

    // 处理无数据状态
    if (_cachedServers == null || _cachedServers!.isEmpty) {
      return [
        PopupMenuItem<void>(
          enabled: false,
          child:
              Text('没有可用的服务器', style: Theme.of(context).textTheme.bodyMedium),
        )
      ];
    }

    // 使用缓存的服务器列表构建菜单项
    for (String serverName in _cachedServers!) {
      // 添加分隔线
      if (menuItems.isNotEmpty) {
        menuItems.add(const PopupMenuDivider());
      }

      // 使用自定义菜单项
      menuItems.add(
        CustomPopupMenuWidget(
          height: 40,
          child: ChangeNotifierProvider.value(
            value: _stateProvider,
            child: Consumer<ServerStateProvider>(
              builder: (context, stateProvider, _) {
                bool isEnabled = stateProvider.isEnabled(serverName);
                bool isRunning = stateProvider.isRunning(serverName);
                bool isStarting = stateProvider.isStarting(serverName);

                // 获取服务器工具数量
                List<Map<String, dynamic>>? serverTools =
                    provider.tools[serverName];
                int toolCount = serverTools?.length ?? 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center, // 确保垂直居中
                  children: [
                    // 服务器名称和工具数量
                    Row(
                      children: [
                        Text(serverName),
                        if (isEnabled && isRunning && toolCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$toolCount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // 直接使用 FlutterSwitch
                    FlutterSwitch(
                      width: 55.0,
                      height: 25.0,
                      value: isEnabled,
                      onToggle: (val) {
                        if (!isStarting) {
                          _handleServerToggle(context, serverName, val);
                        }
                      },
                      toggleSize: 20.0,
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey[300]!,
                      activeToggleColor: Colors.white,
                      inactiveToggleColor: Colors.blue,
                      showOnOff: true,
                      activeText: "ON",
                      inactiveText: "OFF",
                      valueFontSize: 10.0,
                      activeTextColor: Colors.white,
                      inactiveTextColor: Colors.black,
                      activeIcon: isStarting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange),
                              ),
                            )
                          : isRunning
                              ? const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                )
                              : null,
                      disabled: isStarting,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }

    return menuItems;
  }
}

// 自定义菜单项组件
class CustomPopupMenuWidget extends PopupMenuEntry<void> {
  final Widget child;
  final double height;

  const CustomPopupMenuWidget({
    Key? key,
    required this.child,
    this.height = kMinInteractiveDimension,
  }) : super(key: key);

  @override
  State<CustomPopupMenuWidget> createState() => _CustomPopupMenuWidgetState();

  @override
  bool represents(void value) => false;
}

class _CustomPopupMenuWidgetState extends State<CustomPopupMenuWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      alignment: AlignmentDirectional.centerStart,
      child: widget.child,
    );
  }
}
