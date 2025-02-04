import 'package:flutter/material.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import './model_selector.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'dart:io';
import 'package:ChatMcp/utils/platform.dart';

class TopToolbar extends StatelessWidget {
  final bool hideSidebar;
  final VoidCallback onToggleSidebar;

  const TopToolbar({
    super.key,
    required this.hideSidebar,
    required this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () async {
        bool isMaximized = await WindowManagerPlus.current.isMaximized();
        if (isMaximized) {
          await WindowManagerPlus.current.unmaximize();
        } else {
          await WindowManagerPlus.current.maximize();
        }
      },
      child: Container(
        height: 40,
        color: Colors.grey[200],
        padding: kIsDesktop
            ? EdgeInsets.fromLTRB(hideSidebar ? 70 : 0, 0, 16, 0)
            : EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Row(
          children: [
            if (hideSidebar && kIsDesktop)
              IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Colors.grey[700],
                ),
                onPressed: onToggleSidebar,
              ),
            const ModelSelector(),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                ProviderManager.chatProvider.clearActiveChat();
              },
            ),
          ],
        ),
      ),
    );
  }
}
