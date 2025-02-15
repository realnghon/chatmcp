import 'package:flutter/material.dart';
import 'keys_setting.dart';
import 'mcp_server.dart';
import 'general_setting.dart';
import 'package:ChatMcp/utils/color.dart';
import 'tools_setting.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  int _selectedIndex = 0;

  final List<SettingTab> _tabs = [
    SettingTab(
      title: 'General',
      icon: Icons.settings,
      content: const GeneralSettings(),
    ),
    SettingTab(
      title: 'Providers',
      icon: Icons.api,
      content: const KeysSettings(),
    ),
    // SettingTab(
    //   title: 'Tools',
    //   icon: Icons.build,
    //   content: const ToolsSettings(),
    // ),
    SettingTab(
      title: 'MCP Server',
      icon: Icons.storage,
      content: const McpServer(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            tabs: _tabs
                .map((tab) => Tab(
                      icon: Icon(tab.icon),
                      text: tab.title,
                    ))
                .toList(),
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
        body: TabBarView(
          children: _tabs.map((tab) => tab.content).toList(),
        ),
      ),
    );
  }
}

// 选项卡数据模型
class SettingTab {
  final String title;
  final IconData icon;
  final Widget content;

  SettingTab({
    required this.title,
    required this.icon,
    required this.content,
  });
}
