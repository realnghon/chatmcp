import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './chat_page/chat_page.dart';
import 'sidebar.dart';
import './widgets/top_toolbar.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import 'package:ChatMcp/provider/chat_model_provider.dart';
import 'package:ChatMcp/utils/platform.dart';
import 'package:ChatMcp/utils/color.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  bool hideSidebar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProviderManager.chatModelProvider.loadAvailableModels();
    });
  }

  void _toggleSidebar() {
    setState(() {
      hideSidebar = !hideSidebar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatModelProvider>(
      builder: (context, chatModelProvider, child) {
        return KeyboardDismisser(
          gestures: [
            GestureType.onTap,
            GestureType.onPanUpdateDownDirection,
          ],
          child: SafeArea(
            child: Row(
              children: [
                if (kIsDesktop && !hideSidebar)
                  Container(
                    width: 250,
                    color: AppColors.grey[200],
                    child: SidebarPanel(
                      onToggle: _toggleSidebar,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      TopToolbar(
                        hideSidebar: hideSidebar,
                        onToggleSidebar: _toggleSidebar,
                      ),
                      Expanded(
                        child: ChatPage(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
