import 'package:flutter/material.dart';
import 'package:ChatMcp/llm/model.dart';
import 'package:flutter/rendering.dart';
import 'chat_message.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class MessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(ChatMessage) onRetry;
  final Function(String messageId) onSwitch;
  const MessageList({
    super.key,
    required this.messages,
    required this.onRetry,
    required this.onSwitch,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();
  bool _userScrolled = false;

  void resetUserScrolled() {
    setState(() {
      _userScrolled = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom({bool withDelay = true}) {
    if (withDelay) {
      for (var delay in [50, 150, 300, 500]) {
        _delayScrollToBottom(delay);
      }
    } else {
      for (var i = 0; i < 5; i++) {
        _scrollToBottom1();
      }
    }
  }

  void _delayScrollToBottom(int delay) {
    Future.delayed(Duration(milliseconds: delay), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: delay),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _scrollToBottom1() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToBottom(withDelay: false);
    if (widget.messages.length > oldWidget.messages.length) {
      resetUserScrolled();
    }
  }

  @override
  void initState() {
    super.initState();
    // 添加滚动监听器
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection !=
          ScrollDirection.idle) {
        _userScrolled = true;
      }
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        if (isKeyboardVisible) {
          _scrollToBottom();
        }

        // 将消息分组
        List<List<ChatMessage>> groupedMessages = [];
        List<ChatMessage> currentGroup = [];

        for (var msg in widget.messages) {
          if (msg.role == MessageRole.user) {
            if (currentGroup.isNotEmpty) {
              groupedMessages.add(currentGroup);
              currentGroup = [];
            }
            currentGroup.add(msg);
            groupedMessages.add(currentGroup);
            currentGroup = [];
          } else {
            currentGroup.add(msg);
          }
        }

        if (currentGroup.isNotEmpty) {
          groupedMessages.add(currentGroup);
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8.0),
          itemCount: groupedMessages.length,
          // physics: const ClampingScrollPhysics(), // 禁用弹性效果
          itemBuilder: (context, index) {
            final group = groupedMessages[index];

            return ChatUIMessage(
              messages: group,
              onRetry: widget.onRetry,
              onSwitch: widget.onSwitch,
            );
          },
        );
      },
    );
  }
}
