import 'package:flutter/material.dart';
import '../setting/setting.dart';
import 'package:provider/provider.dart';
import 'package:chatmcp/provider/chat_provider.dart';
import 'package:chatmcp/utils/platform.dart';
import 'package:chatmcp/utils/color.dart';

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

  Map<String, List<dynamic>> _groupChats(List<dynamic> chats) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final previous7Days = today.subtract(const Duration(days: 7));
    final previous30Days = today.subtract(const Duration(days: 30));

    return {
      '今天': chats.where((chat) {
        final chatDate = DateTime(
            chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isAtSameMomentAs(today);
      }).toList(),
      '昨天': chats.where((chat) {
        final chatDate = DateTime(
            chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isAtSameMomentAs(yesterday);
      }).toList(),
      '前 7 天': chats.where((chat) {
        final chatDate = DateTime(
            chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isBefore(yesterday) && chatDate.isAfter(previous7Days);
      }).toList(),
      '前 30 天': chats.where((chat) {
        final chatDate = DateTime(
            chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isBefore(previous7Days) &&
            chatDate.isAfter(previous30Days);
      }).toList(),
      '更早': chats.where((chat) {
        final chatDate = DateTime(
            chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isBefore(previous30Days);
      }).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final groupedChats = _groupChats(chatProvider.chats);

    return Container(
      padding: const EdgeInsets.only(top: 30, left: 4, right: 4, bottom: 40),
      child: ListView.builder(
        itemCount: groupedChats.entries.length,
        itemBuilder: (context, index) {
          final entry = groupedChats.entries.elementAt(index);
          if (entry.value.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getThemeTextColor(context).withAlpha(128),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ...entry.value.map((chat) => ChatHistoryItem(
                    chat: chat,
                    chatProvider: chatProvider,
                  )),
            ],
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
        color: isActive
            ? AppColors.getThemeColor(context,
                lightColor: AppColors.grey[300], darkColor: AppColors.grey[700])
            : null,
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
