import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/mcp_server_provider.dart';
import 'package:logging/logging.dart';
import 'dart:io';
import 'package:chatmcp/utils/process.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withAlpha(204),
            ],
          ),
        ),
        child: Consumer<McpServerProvider>(
          builder: (context, provider, child) {
            if (!provider.isSupported) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      l10n.platformNotSupported,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      l10n.mcpServerDesktopOnly,
                      style: TextStyle(
                        color: AppColors.getThemeTextColor(context),
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
                        hintText: l10n.searchServer,
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.getThemeTextColor(context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.getThemeColor(context,
                            lightColor: AppColors.grey[200],
                            darkColor: AppColors.grey[800]),
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
                      _buildFilterChip(l10n.all),
                      const SizedBox(width: 12),
                      _buildFilterChip(l10n.installed),
                      const Spacer(),
                      _buildActionButton(
                        icon: Icons.add,
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
                        icon: Icons.refresh,
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
                                  color: AppColors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load: ${snapshot.error}',
                                  style: const TextStyle(color: AppColors.red),
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
                                    color: AppColors.getThemeTextColor(context),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.noServerConfigs,
                                    style: TextStyle(
                                      color:
                                          AppColors.getThemeTextColor(context),
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
    final l10n = AppLocalizations.of(context)!;
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
            color: AppColors.grey.withAlpha(51),
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
            color: AppColors.getThemeTextColor(context),
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
                                    tooltip: l10n.edit,
                                    onPressed: () => _showEditDialog(
                                        context, serverName, provider, null),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionButton(
                                    icon: Icons.delete,
                                    tooltip: l10n.delete,
                                    color: AppColors.red,
                                    onPressed: () => _showDeleteConfirmDialog(
                                        context, serverName, provider),
                                  ),
                                ] else
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: Text(l10n.install),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors.getThemeTextColor(context),
                                      foregroundColor: AppColors.white,
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
                                          l10n.commandNotExist(
                                              serverConfig['command'],
                                              Platform.environment['PATH'] ??
                                                  ''),
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
                        tooltip: l10n.edit,
                        onPressed: () => _showEditDialog(
                            context, serverName, provider, null),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete,
                        tooltip: l10n.delete,
                        color: AppColors.red,
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
            color: AppColors.grey,
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
        color: AppColors.transparent,
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
    final l10n = AppLocalizations.of(context)!;
    if (_selectedTab == 'All') {
      _selectedTab = l10n.all;
    }
    final isSelected = _selectedTab == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppColors.getThemeTextColor(context)
              : AppColors.getThemeTextColor(context),
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTab = label;
        });
      },
      selectedColor: AppColors.getThemeTextColor(context).withAlpha(38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? AppColors.getThemeTextColor(context).withAlpha(128)
              : AppColors.grey.withAlpha(51),
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

      final l10n = AppLocalizations.of(context)!;
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
                    decoration: InputDecoration(
                      labelText: l10n.serverName,
                    ),
                  ),
                TextField(
                  controller: commandController,
                  decoration: InputDecoration(
                    labelText: l10n.command,
                    hintText: l10n.commandExample,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: argsController,
                  decoration: InputDecoration(
                    labelText: l10n.arguments,
                    hintText: l10n.argumentsExample,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: envController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.environmentVariables,
                    hintText: l10n.envVarsFormat,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.save),
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
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
