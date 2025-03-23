import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatmcp/provider/mcp_server_provider.dart';
import 'package:chatmcp/generated/app_localizations.dart';

class McpTools extends StatelessWidget {
  const McpTools({super.key});

  List<PopupMenuEntry<void>> _buildToolMenuItems(
      BuildContext context, Map<String, dynamic> tools) {
    List<PopupMenuEntry<void>> menuItems = [];

    tools.forEach((category, toolsList) {
      // 添加类别标题
      if (menuItems.isNotEmpty) {
        menuItems.add(const PopupMenuDivider());
      }

      menuItems.add(
        PopupMenuItem<void>(
          enabled: false,
          height: 16,
          child: Text(
            category,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );

      // 添加该类别下的所有工具
      if (toolsList is List) {
        for (var toolData in toolsList) {
          if (toolData is Map &&
              toolData.containsKey("name") &&
              toolData.containsKey("description")) {
            menuItems.add(
              PopupMenuItem<void>(
                height: 64, // 增加高度以容纳更多描述文本
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        toolData["name"],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        toolData["description"].toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
      }
    });

    if (menuItems.isEmpty) {
      menuItems.add(
        PopupMenuItem<void>(
          enabled: false,
          child: Text('No tools available',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    return menuItems;
  }

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    return Consumer<McpServerProvider>(
      builder: (context, mcpServerProvider, child) {
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
          itemBuilder: (context) =>
              _buildToolMenuItems(context, mcpServerProvider.tools),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tools: ${mcpServerProvider.tools.length}'),
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
}
