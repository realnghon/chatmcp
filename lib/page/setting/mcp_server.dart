import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../provider/mcp_server_provider.dart';
import 'package:logging/logging.dart';
import 'dart:io';
import 'package:chatmcp/utils/process.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/generated/app_localizations.dart';

class McpServer extends StatefulWidget {
  const McpServer({super.key});

  @override
  State<McpServer> createState() => _McpServerState();
}

class _McpServerState extends State<McpServer> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Consumer<McpServerProvider>(
          builder: (context, provider, child) {
            if (!provider.isSupported) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.platformNotSupported,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.mcpServerDesktopOnly,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 搜索框
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            Theme.of(context).colorScheme.outline.withAlpha(26),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchServer,
                        prefixIcon: Icon(
                          CupertinoIcons.search,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(153),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 标签选择和操作按钮
                  Row(
                    children: [
                      _buildFilterChip(l10n.all),
                      const SizedBox(width: 12),
                      _buildFilterChip(l10n.installed),
                      const Spacer(),
                      _buildActionButton(
                        icon: CupertinoIcons.add,
                        tooltip: l10n.addServer,
                        onPressed: () {
                          final provider = Provider.of<McpServerProvider>(
                              context,
                              listen: false);
                          _showEditDialog(context, '', provider, null);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: CupertinoIcons.refresh,
                        tooltip: l10n.refresh,
                        onPressed: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 服务器列表
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _selectedTab == l10n.all
                          ? provider.loadMarketServers()
                          : provider.loadServers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_circle,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load: ${snapshot.error}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
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
                                    CupertinoIcons.desktopcomputer,
                                    size: 64,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(153),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.noServerConfigs,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(153),
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
                        return const Center(
                            child: CupertinoActivityIndicator());
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha(26),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          serverName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        shape: const RoundedRectangleBorder(
          side: BorderSide.none,
        ),
        leading: Icon(
          CupertinoIcons.desktopcomputer,
          color: Theme.of(context).colorScheme.primary,
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(l10n.command, serverConfig['command'] ?? ''),
              const SizedBox(height: 8),
              _buildInfoRow(l10n.arguments,
                  (serverConfig['args'] as List?)?.join(' ') ?? ''),
              if (serverConfig['env'] != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  l10n.environmentVariables,
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
                          final installedServers = snapshot.data?['mcpServers']
                                  as Map<String, dynamic>? ??
                              {};
                          final isInstalled =
                              installedServers.containsKey(serverName);

                          return Row(
                            children: [
                              if (isInstalled) ...[
                                _buildActionButton(
                                  icon: CupertinoIcons.pencil,
                                  tooltip: l10n.edit,
                                  onPressed: () => _showEditDialog(
                                      context, serverName, provider, null),
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  icon: CupertinoIcons.delete,
                                  tooltip: l10n.delete,
                                  color: Theme.of(context).colorScheme.error,
                                  onPressed: () => _showDeleteConfirmDialog(
                                      context, serverName, provider),
                                ),
                              ] else
                                ElevatedButton.icon(
                                  icon: Icon(
                                    CupertinoIcons.cloud_download,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  label: Text(l10n.install),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final cmdExists = await isCommandAvailable(
                                        serverConfig['command']);
                                    if (!cmdExists) {
                                      showErrorDialog(
                                        context,
                                        l10n.commandNotExist(
                                            serverConfig['command'],
                                            Platform.environment['PATH'] ?? ''),
                                      );
                                    } else {
                                      Logger.root.info(
                                        'Install server configuration: $serverName ${serverConfig['command']} ${serverConfig['args']}',
                                      );
                                      await _showEditDialog(context, serverName,
                                          provider, serverConfig);
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
                      icon: CupertinoIcons.pencil,
                      tooltip: l10n.edit,
                      onPressed: () =>
                          _showEditDialog(context, serverName, provider, null),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: CupertinoIcons.delete,
                      tooltip: l10n.delete,
                      color: Theme.of(context).colorScheme.error,
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
                color: color ??
                    Theme.of(context).colorScheme.primary.withAlpha(51),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedTab == 'All') {
      _selectedTab = l10n.all;
    }
    final isSelected = _selectedTab == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTab = label;
        });
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary.withAlpha(31),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withAlpha(26),
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

    final serverNameController = TextEditingController(text: serverName);
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

    String? resultServerName;
    String? resultCommand;
    String? resultArgs;
    String? resultEnv;

    try {
      if (!context.mounted) {
        serverNameController.dispose();
        commandController.dispose();
        argsController.dispose();
        envController.dispose();
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // 防止点击外部关闭对话框
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(
            'MCP Server - $serverName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (serverName.isEmpty)
                  TextField(
                    controller: serverNameController,
                    onChanged: (value) => resultServerName = value,
                    decoration: InputDecoration(
                      labelText: l10n.serverName,
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(102),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withAlpha(51),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withAlpha(51),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      prefixIcon: Icon(
                        CupertinoIcons.command,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                if (serverName.isEmpty) const SizedBox(height: 16),
                TextField(
                  controller: commandController,
                  onChanged: (value) => resultCommand = value,
                  decoration: InputDecoration(
                    labelText: l10n.command,
                    hintText: l10n.commandExample,
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(102),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Theme.of(context).colorScheme.outline.withAlpha(51),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Theme.of(context).colorScheme.outline.withAlpha(51),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.command,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: argsController,
                  onChanged: (value) => resultArgs = value,
                  decoration: InputDecoration(
                    labelText: l10n.arguments,
                    hintText: l10n.argumentsExample,
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(102),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Theme.of(context).colorScheme.outline.withAlpha(51),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Theme.of(context).colorScheme.outline.withAlpha(51),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.command,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: envController,
                  onChanged: (value) => resultEnv = value,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.environmentVariables,
                    hintText: l10n.envVarsFormat,
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(102),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Theme.of(context).colorScheme.outline.withAlpha(51),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Theme.of(context).colorScheme.outline.withAlpha(51),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.command,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withAlpha(31),
              ),
              child: Text(
                l10n.save,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      );

      if (confirmed == true && context.mounted) {
        // 解析环境变量
        final env = Map<String, String>.fromEntries(
          (resultEnv ?? envController.text)
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

        final saveServerName = serverName.isEmpty
            ? (resultServerName ?? serverNameController.text).trim()
            : serverName;

        config['mcpServers'][saveServerName] = {
          'command': (resultCommand ?? commandController.text).trim(),
          'args':
              (resultArgs ?? argsController.text).trim().split(RegExp(r'\s+')),
          'env': env,
        };

        await provider.saveServers(config);
        setState(() {});
      }
    } finally {
      // 确保控制器被释放
      serverNameController.dispose();
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteServer(serverName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
