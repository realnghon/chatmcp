import 'package:flutter/material.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import './model_selector.dart';
import 'package:window_manager/window_manager.dart' as wm;
import 'package:ChatMcp/utils/platform.dart';
import 'package:ChatMcp/utils/color.dart';
import 'package:provider/provider.dart';
import 'package:ChatMcp/provider/chat_provider.dart';

// test page
import 'package:ChatMcp/widgets/markdown/markit_widget.dart';
import 'package:ChatMcp/widgets/browser/browser.dart';
import 'package:ChatMcp/utils/event_bus.dart';
import 'package:ChatMcp/page/layout/widgets/chat_setting.dart';

class TopToolbar extends StatelessWidget {
  final bool hideSidebar;
  final VoidCallback onToggleSidebar;

  const TopToolbar({
    super.key,
    required this.hideSidebar,
    required this.onToggleSidebar,
  });

  void _onShowChatSetting(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: const ChatSetting(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      if (ProviderManager.chatProvider.activeChat != null)
                        PopupMenuItem<String>(
                          value: 'share',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_outward),
                              const SizedBox(width: 8),
                              const Text('分享'),
                            ],
                          ),
                        ),
                      PopupMenuItem<String>(
                        value: 'config',
                        onTap: () => _onShowChatSetting(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tune),
                            const SizedBox(width: 8),
                            const Text('模型配置'),
                          ],
                        ),
                      ),
                      if (kIsDebug)
                        PopupMenuItem<String>(
                          value: 'debug',
                          child: Row(
                            children: [
                              const Icon(Icons.bug_report),
                              const SizedBox(width: 8),
                              const Text('调试'),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (String value) {
                      switch (value) {
                        case 'share':
                          emit(ShareEvent(false));
                          break;
                        case 'debug':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: const Text('web search 测试'),
                                ),
                                body: BrowserView(
                                  url: 'rag embeddings',
                                ),
                              ),
                            ),
                          );
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
