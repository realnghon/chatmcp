import 'package:chatmcp/widgets/ink_icon.dart';
import 'package:flutter/material.dart';
import '../setting/setting.dart';
import 'package:provider/provider.dart';
import 'package:chatmcp/provider/chat_provider.dart';
import 'package:chatmcp/utils/platform.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:chatmcp/components/widgets/base.dart';
import 'package:chatmcp/page/layout/widgets/app_info.dart';

class SidebarPanel extends StatefulWidget {
  final VoidCallback? onToggle;
  const SidebarPanel({super.key, this.onToggle});

  @override
  State<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends State<SidebarPanel> {
  bool _isSearchVisible = false;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void toggleSearchVisibility() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchText = '';
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) => SizedBox(
        height: double.infinity,
        child: Column(
          children: [
            // 顶部区域
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  if (kIsWindows || kIsLinux || kIsMobile || kIsBrowser) ...[
                    Image.asset(
                      'assets/logo.png',
                      width: 24,
                      height: 24,
                    ),
                    const Gap(size: 8),
                    CText(
                      text: 'ChatMCP',
                      size: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                  const Spacer(),
                  InkIcon(
                    icon: CupertinoIcons.search,
                    onTap: toggleSearchVisibility,
                    tooltip: AppLocalizations.of(context)!.search,
                  ),
                  if (kIsDesktop) ...[
                    const Gap(size: 8),
                    InkIcon(
                      icon: CupertinoIcons.sidebar_left,
                      onTap: widget.onToggle,
                      tooltip: AppLocalizations.of(context)!.toggleSidebar,
                    ),
                  ],
                ],
              ),
            ),

            // 搜索框
            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.getThemeColor(
                      context,
                      lightColor: Colors.grey[300],
                      darkColor: Colors.grey[600],
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.search,
                      hintStyle: const TextStyle(fontSize: 12),
                      suffixIcon: IconButton(
                        icon: const Icon(CupertinoIcons.clear, size: 14),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchText = '';
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: InputBorder.none,
                      isDense: true,
                      isCollapsed: true,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 12),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                  ),
                ),
              ),

            // 中间区域 - 聊天历史列表
            Expanded(
              child: ChatHistoryList(
                chatProvider: chatProvider,
                searchText: _searchText,
              ),
            ),

            // 底部区域
            SidebarToolbar(chatProvider: chatProvider),
          ],
        ),
      ),
    );
  }
}

class ChatHistoryList extends StatelessWidget {
  final ChatProvider chatProvider;
  final String searchText;

  const ChatHistoryList({
    super.key,
    required this.chatProvider,
    this.searchText = '',
  });

  Map<String, List<dynamic>> _groupChats(BuildContext context, List<dynamic> chats) {
    // 过滤聊天记录
    final filteredChats = searchText.isEmpty
        ? chats
        : chats.where((chat) {
            return chat.title.toLowerCase().contains(searchText.toLowerCase());
          }).toList();

    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final previous7Days = today.subtract(const Duration(days: 7));
    final previous30Days = today.subtract(const Duration(days: 30));

    return {
      l10n.today: filteredChats.where((chat) {
        final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isAtSameMomentAs(today);
      }).toList(),
      l10n.yesterday: filteredChats.where((chat) {
        final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isAtSameMomentAs(yesterday);
      }).toList(),
      l10n.last7Days: filteredChats.where((chat) {
        final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isBefore(yesterday) && chatDate.isAfter(previous7Days);
      }).toList(),
      l10n.last30Days: filteredChats.where((chat) {
        final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isBefore(previous7Days) && chatDate.isAfter(previous30Days);
      }).toList(),
      l10n.earlier: filteredChats.where((chat) {
        final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
        return chatDate.isBefore(previous30Days);
      }).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final groupedChats = _groupChats(context, chatProvider.chats);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: CText(
                  text: entry.key,
                  size: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ...entry.value.map(
                (chat) => ChatHistoryItem(
                  chat: chat,
                  chatProvider: chatProvider,
                ),
              ),
              const Gap(size: 12),
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
    final l10n = AppLocalizations.of(context)!;
    final backgroundColor = AppColors.getThemeColor(context, lightColor: Colors.white, darkColor: Colors.grey[800]);

    // 创建弹出菜单的内容
    Widget popupContent = Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context); // 关闭弹窗
              _showDeleteConfirmDialog(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.delete, size: 18, color: Colors.red),
                  const Gap(size: 8),
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // 创建聊天项
    Widget chatItem = ListTile(
      dense: true,
      visualDensity: VisualDensity(vertical: -4),
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
            child: CText(
              text: chat.title.replaceAll('\n', ' '),
              size: 12,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onTap: () {
        if (chatProvider.isSelectMode) {
          chatProvider.toggleSelectChat(chat.id);
        } else {
          chatProvider.setActiveChat(chat);
          if (kIsMobile) {
            Navigator.pop(context);
          }
        }
      },
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.getSidebarActiveConversationColor(context) : null,
        borderRadius: BorderRadius.circular(7),
      ),
      child: kIsDesktop
          ? _buildDesktopChatItem(context, chatItem, popupContent, backgroundColor)
          : _buildMobileChatItem(context, chatItem, popupContent, backgroundColor),
    );
  }

  // 桌面端构建方法：右键触发
  Widget _buildDesktopChatItem(BuildContext context, Widget chatItem, Widget popupContent, Color? backgroundColor) {
    return GestureDetector(
      onSecondaryTapDown: (TapDownDetails details) {
        _showCustomPopup(context, popupContent, backgroundColor, details.globalPosition);
      },
      child: chatItem,
    );
  }

  // 移动端构建方法：长按触发
  Widget _buildMobileChatItem(BuildContext context, Widget chatItem, Widget popupContent, Color? backgroundColor) {
    return GestureDetector(
      onLongPressStart: (LongPressStartDetails details) {
        _showCustomPopup(context, popupContent, backgroundColor, details.globalPosition);
      },
      child: chatItem,
    );
  }

  // 显示自定义弹出窗口
  void _showCustomPopup(BuildContext context, Widget content, Color? backgroundColor, Offset position) {
    // 估计弹出菜单的宽度
    const double estimatedPopupWidth = 150.0;

    // 计算屏幕宽度
    final double screenWidth = MediaQuery.of(context).size.width;

    // 计算合适的left位置，使菜单靠右显示
    double left = position.dx;

    // 确保菜单不会超出屏幕左边界
    left = left < 10 ? 10 : left;

    // 确保菜单不会超出屏幕右边界
    if (left + estimatedPopupWidth > screenWidth - 10) {
      left = screenWidth - estimatedPopupWidth - 10;
    }

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: position.dy,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8.0),
                color: backgroundColor,
                child: content,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteSelected),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              chatProvider.deleteChat(chat.id);
              Navigator.pop(context);
            },
            child: Text(l10n.ok),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          _buildSettingsButton(context),
          const Gap(size: 4),
          _buildSelectModeButton(context),
          if (chatProvider.isSelectMode) ...[
            const Gap(size: 4),
            _buildSelectAllButton(context),
            const Gap(size: 4),
            _buildDeleteButton(context),
          ],
          const Spacer(),
          const AppInfo(),
          const Gap(size: 4),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return InkIcon(
      icon: CupertinoIcons.settings,
      onTap: () => _showSettingsDialog(context),
      tooltip: AppLocalizations.of(context)!.settings,
    );
  }

  Widget _buildSelectModeButton(BuildContext context) {
    return InkIcon(
      icon: chatProvider.isSelectMode ? CupertinoIcons.clear : CupertinoIcons.trash,
      onTap: () {
        if (chatProvider.isSelectMode) {
          chatProvider.exitSelectMode();
        } else {
          chatProvider.enterSelectMode();
        }
      },
      tooltip: AppLocalizations.of(context)!.deleteChat,
    );
  }

  Widget _buildSelectAllButton(BuildContext context) {
    return InkIcon(
      icon: CupertinoIcons.checkmark_square,
      onTap: () => chatProvider.toggleSelectAll(),
      tooltip: AppLocalizations.of(context)!.selectAll,
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return InkIcon(
      icon: CupertinoIcons.delete,
      onTap: chatProvider.selectedChats.isNotEmpty ? () => _showDeleteConfirmDialog(context) : null,
      tooltip: AppLocalizations.of(context)!.delete,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: const SettingPage(),
            ),
          ),
        ),
      );
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteSelected),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              chatProvider.deleteSelectedChats();
              Navigator.pop(context);
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
