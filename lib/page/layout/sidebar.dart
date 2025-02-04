import 'package:flutter/material.dart';
import '../setting/setting.dart';
import 'package:provider/provider.dart';
import 'package:ChatMcp/provider/chat_provider.dart';
import 'package:ChatMcp/utils/platform.dart';

class SidebarPanel extends StatelessWidget {
  final VoidCallback? onToggle;
  const SidebarPanel({super.key, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) => SizedBox(
        height: double.infinity,
        child: Stack(
          children: [
            ChatHistoryList(chatProvider: chatProvider),
            if (kIsDesktop) ...[
              Positioned(
                top: 0,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: onToggle,
                ),
              ),
            ],
            SidebarToolbar(chatProvider: chatProvider),
          ],
        ),
      ),
    );
  }
}

class ChatHistoryList extends StatelessWidget {
  final ChatProvider chatProvider;

  const ChatHistoryList({
    super.key,
    required this.chatProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 30, left: 4, right: 4, bottom: 40),
      child: ListView.builder(
        itemCount: chatProvider.chats.length,
        itemBuilder: (context, index) {
          final chat = chatProvider.chats[index];
          return ChatHistoryItem(
            chat: chat,
            chatProvider: chatProvider,
          );
        },
      ),
    );
  }
}

class ChatHistoryItem extends StatelessWidget {
  final dynamic chat;
  final ChatProvider chatProvider;

  const ChatHistoryItem({
    super.key,
    required this.chat,
    required this.chatProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = chat.id == chatProvider.activeChat?.id;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? Colors.grey.withAlpha(25) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -4),
        leading: chatProvider.isSelectMode
            ? Checkbox(
                value: chatProvider.selectedChats.contains(chat.id),
                onChanged: (bool? value) {
                  if (value == true) {
                    chatProvider.selectChat(chat.id);
                  } else {
                    chatProvider.unselectChat(chat.id);
                  }
                },
              )
            : null,
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.title,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${chat.updatedAt.month}/${chat.updatedAt.day}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          chatProvider.isSelectMode
              ? chatProvider.toggleSelectChat(chat.id)
              : chatProvider.setActiveChat(chat);

          if (kIsMobile) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

class SidebarToolbar extends StatelessWidget {
  final ChatProvider chatProvider;

  const SidebarToolbar({
    super.key,
    required this.chatProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            _buildSettingsButton(context),
            _buildSelectModeButton(),
            if (chatProvider.isSelectMode) ...[
              _buildSelectAllButton(),
              _buildDeleteButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () => _showSettingsDialog(context),
    );
  }

  Widget _buildSelectModeButton() {
    return IconButton(
      icon: Icon(chatProvider.isSelectMode ? Icons.close : Icons.delete),
      onPressed: () {
        if (chatProvider.isSelectMode) {
          chatProvider.exitSelectMode();
        } else {
          chatProvider.enterSelectMode();
        }
      },
    );
  }

  Widget _buildSelectAllButton() {
    return IconButton(
      icon: const Icon(Icons.select_all),
      onPressed: () => chatProvider.toggleSelectAll(),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return ElevatedButton(
      onPressed: chatProvider.selectedChats.isNotEmpty
          ? () => _showDeleteConfirmDialog(context)
          : null,
      child: const Text('删除'),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    if (kIsMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingPage(),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            child: const SettingPage(),
          ),
        ),
      );
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除选中的对话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              chatProvider.deleteSelectedChats();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
