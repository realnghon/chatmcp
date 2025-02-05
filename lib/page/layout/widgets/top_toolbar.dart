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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: () async {
          debugPrint('double tap');
          if (kIsDesktop) {
            try {
              bool isMaximized = await WindowManagerPlus.current.isMaximized();
              if (isMaximized) {
                await WindowManagerPlus.current.unmaximize();
              } else {
                await WindowManagerPlus.current.maximize();
              }
            } catch (e) {
              debugPrint('窗口操作失败: $e');
            }
          }
        },
        child: Container(
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
      ),
    );
  }
}
