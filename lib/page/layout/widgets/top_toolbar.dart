import 'package:flutter/material.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import './model_selector.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class TopToolbar extends StatelessWidget {
  final bool hideChatHistory;
  final VoidCallback onToggleChatHistory;

  const TopToolbar({
    super.key,
    required this.hideChatHistory,
    required this.onToggleChatHistory,
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
        color: Colors.grey[100],
        padding: EdgeInsets.fromLTRB(hideChatHistory ? 70 : 0, 0, 16, 0),
        child: Row(
          children: [
            if (hideChatHistory)
              IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Colors.grey[700],
                ),
                onPressed: onToggleChatHistory,
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
