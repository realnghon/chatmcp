import 'package:flutter/material.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import './model_selector.dart';
import 'package:window_manager/window_manager.dart' as wm;
import 'package:ChatMcp/utils/platform.dart';
import 'package:ChatMcp/utils/color.dart';
import 'package:ChatMcp/widgets/markdown/markit_widget.dart';

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
              bool isMaximized = await wm.windowManager.isMaximized();
              if (isMaximized) {
                await wm.windowManager.unmaximize();
              } else {
                await wm.windowManager.maximize();
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
              if (kIsDebug)
                IconButton(
                  icon: const Icon(Icons.bug_report),
                  onPressed: () {
                    // jump to the top of the page
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MarkitTestPage(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
