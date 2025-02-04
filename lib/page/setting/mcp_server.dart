import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/mcp_server_provider.dart';
import 'package:logging/logging.dart';
import 'dart:io';
import 'package:ChatMcp/utils/process.dart';

class McpServer extends StatefulWidget {
  const McpServer({super.key});

  @override
  State<McpServer> createState() => _McpServerState();
}

class _McpServerState extends State<McpServer> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'All';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withAlpha(204),
            ],
          ),
        ),
        child: Consumer<McpServerProvider>(
          builder: (context, provider, child) {
            if (!provider.isSupported) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '当前平台不支持 MCP Server',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'MCP Server 仅支持桌面端（Windows、macOS、Linux）',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // 搜索框
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search server...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 标签选择和操作按钮
                  Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 12),
                      _buildFilterChip('Installed'),
                      const Spacer(),
                      _buildActionButton(
                        icon: Icons.add,
                        tooltip: 'Add Server',
                        onPressed: () {
                          final provider = Provider.of<McpServerProvider>(
                              context,
                              listen: false);
                          _showEditDialog(context, '', provider, null);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.refresh,
                        tooltip: 'Refresh',
                        onPressed: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 服务器列表
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _selectedTab == 'All'
                          ? provider.loadMarketServers()
                          : provider.loadServers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }

                        if (snapshot.hasData) {
                          final servers = snapshot.data?['mcpServers']
                                  as Map<String, dynamic>? ??
                              {};

                          if (servers.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dns_outlined,
                                    size: 64,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No server configurations found',
                                    style: TextStyle(
                                      color: Theme.of(context).disabledColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: servers.length,
                            itemBuilder: (context, index) {
                              final serverName = servers.keys.elementAt(index);
                              final serverConfig = servers[serverName];

                              return _buildServerCard(
                                context,
                                serverName,
                                serverConfig,
                                provider,
                              );
                            },
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServerCard(
    BuildContext context,
    String serverName,
    dynamic serverConfig,
    McpServerProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withAlpha(51),
          ),
        ),
        child: ExpansionTile(
          title: Text(
            serverName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          shape: const RoundedRectangleBorder(
            side: BorderSide.none,
          ),
          leading: Icon(
            Icons.dns,
            color: Theme.of(context).primaryColor,
          ),
          childrenPadding: const EdgeInsets.all(16),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Command', serverConfig['command'] ?? ''),
                const SizedBox(height: 8),
                _buildInfoRow('Arguments',
                    (serverConfig['args'] as List?)?.join(' ') ?? ''),
                if (serverConfig['env'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Environment Variables',
                    (serverConfig['env'] as Map?)
                            ?.entries
                            .map((e) => '${e.key}=${e.value}')
                            .join('\n') ??
                        '',
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_selectedTab == 'All')
                      FutureBuilder<Map<String, dynamic>>(
                        future: provider.loadServers(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final installedServers =
                                snapshot.data?['mcpServers']
                                        as Map<String, dynamic>? ??
                                    {};
                            final isInstalled =
                                installedServers.containsKey(serverName);

                            return Row(
                              children: [
                                if (isInstalled) ...[
                                  _buildActionButton(
                                    icon: Icons.edit,
                                    tooltip: 'Edit',
                                    onPressed: () => _showEditDialog(
                                        context, serverName, provider, null),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionButton(
                                    icon: Icons.delete,
                                    tooltip: 'Delete',
                                    color: Colors.red,
                                    onPressed: () => _showDeleteConfirmDialog(
                                        context, serverName, provider),
                                  ),
                                ] else
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: const Text('Install'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final cmdExists =
                                          await isCommandAvailable(
                                              serverConfig['command']);
                                      if (!cmdExists) {
                                        showErrorDialog(
                                          context,
                                          'Command "${serverConfig['command']}" does not exist, please install it first\n\nCurrent PATH:\n${Platform.environment['PATH']}',
                                        );
                                      } else {
                                        Logger.root.info(
                                          'Install server configuration: $serverName ${serverConfig['command']} ${serverConfig['args']}',
                                        );
                                        await _showEditDialog(context,
                                            serverName, provider, serverConfig);
                                      }
                                    },
                                  ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    if (_selectedTab == 'Installed') ...[
                      _buildActionButton(
                        icon: Icons.edit,
                        tooltip: 'Edit',
                        onPressed: () => _showEditDialog(
                            context, serverName, provider, null),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete,
                        tooltip: 'Delete',
                        color: Colors.red,
                        onPressed: () => _showDeleteConfirmDialog(
                            context, serverName, provider),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color ?? Theme.of(context).primaryColor.withAlpha(51),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedTab == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTab = label;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withAlpha(38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor.withAlpha(128)
              : Colors.grey.withAlpha(51),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    String serverName,
    McpServerProvider provider,
    Map<String, dynamic>? newServerConfig,
  ) async {
    if (!context.mounted) return;

    final config = await provider.loadServers();
    final servers = config['mcpServers'] ?? {};

    if (!context.mounted) return;

    final serverConfig = newServerConfig ??
        servers[serverName] as Map<String, dynamic>? ??
        {
          'command': '',
          'args': <String>[],
          'env': <String, String>{},
        };

    final serverNameController = TextEditingController(
      text: serverName,
    );

    final commandController = TextEditingController(
      text: serverConfig['command']?.toString() ?? '',
    );
    final argsController = TextEditingController(
      text: (serverConfig['args'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .join(' ') ??
          '',
    );
    final envController = TextEditingController(
      text: (serverConfig['env'] as Map<String, dynamic>?)
              ?.entries
              .map((e) => '${e.key}=${e.value}')
              .join('\n') ??
          '',
    );

    try {
      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text('MCP Server - $serverName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (serverName.isEmpty)
                  TextField(
                    controller: serverNameController,
                    decoration: const InputDecoration(
                      labelText: 'Server Name',
                    ),
                  ),
                TextField(
                  controller: commandController,
                  decoration: const InputDecoration(
                    labelText: 'Command',
                    hintText: 'For example: npx, uvx',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: argsController,
                  decoration: const InputDecoration(
                    labelText: 'Arguments',
                    hintText:
                        'Separate arguments with spaces, for example: -m mcp.server',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: envController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Environment Variables',
                    hintText: 'One per line, format: KEY=VALUE',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        // 解析环境变量
        final env = Map<String, String>.fromEntries(
          envController.text
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .map((line) {
            final parts = line.split('=');
            if (parts.length < 2) {
              return MapEntry(parts[0].trim(), '');
            }
            return MapEntry(
              parts[0].trim(),
              parts.sublist(1).join('=').trim(),
            );
          }),
        );

        // 更新服务器配置
        if (config['mcpServers'] == null) {
          config['mcpServers'] = <String, dynamic>{};
        }

        final saveServerName =
            serverName.isEmpty ? serverNameController.text.trim() : serverName;

        config['mcpServers'][saveServerName] = {
          'command': commandController.text.trim(),
          'args': argsController.text.trim().split(RegExp(r'\s+')),
          'env': env,
        };

        await provider.saveServers(config);
        setState(() {});
      }
    } finally {
      // 确保控制器被释放
      commandController.dispose();
      argsController.dispose();
      envController.dispose();
    }
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    String serverName,
    McpServerProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete server "$serverName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final config = await provider.loadServers();
      config['mcpServers'].remove(serverName);
      await provider.saveServers(config);
      setState(() {});
    }
  }

  Future<void> showErrorDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
