import 'package:flutter/material.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import './model_selector.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:ChatMcp/utils/platform.dart';
import 'package:ChatMcp/utils/color.dart';

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
        // height: 40,
        // decoration: BoxDecoration(
        //   border: Border.all(color: Colors.red), // 添加红色边框用于调试
        // ),
        // color: AppColors.grey[200],
        padding: kIsDesktop
            ? EdgeInsets.fromLTRB(hideSidebar ? 70 : 0, 0, 16, 0)
            : null,
        child: Row(
          children: [
            if (hideSidebar && kIsDesktop)
              IconButton(
                icon: Icon(
                  Icons.menu,
                  color: AppColors.grey[700],
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
