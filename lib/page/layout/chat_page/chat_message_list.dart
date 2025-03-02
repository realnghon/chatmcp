import 'package:flutter/material.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:flutter/rendering.dart';
import 'chat_message.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'scroll_down_button.dart';

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
  bool _stickToBottom = true;

  bool _isScrolledToBottom({double threshold = 1.0}) {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // 允许1像素的误差
    return (maxScroll - currentScroll).abs() <= threshold;
  }

  Future _scrollToBottom({bool withDelay = true}) async {
    if (withDelay) {
      for (var delay in [50, 150, 300]) {
        _delayScrollToBottom(delay);
      }
    } else {
      if (_isScrolledToBottom()) {
        return;
      }
      await _scrollToBottom1();
      setState(() {
        _stickToBottom = true;
      });
    }
  }

  void _delayScrollToBottom(int delay) {
    Future.delayed(Duration(milliseconds: delay), () {
      if (_isScrolledToBottom()) {
        return;
      }
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: delay),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future _scrollToBottom1() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('MessageList didUpdateWidget $_stickToBottom');
    if (_stickToBottom) {
      _scrollToBottom(withDelay: false);
    }
  }

  @override
  void initState() {
    super.initState();
    // 添加滚动监听器
    _scrollController.addListener(() {
      final direction = _scrollController.position.userScrollDirection;

      if (direction == ScrollDirection.forward &&
          _isScrolledToBottom(threshold: 100.0)) {
        setState(() {
          _stickToBottom = false;
        });
      }

      if (direction != ScrollDirection.idle) {
        if (_isScrolledToBottom()) {
          setState(() {
            _stickToBottom = true;
          });
        }
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

        return Stack(
          children: [
            ListView.builder(
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
            ),
            if (_isScrolledToBottom() == false)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: ScrollDownButton(
                    onPressed: () {
                      _stickToBottom = true;
                      _scrollToBottom(withDelay: false);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
