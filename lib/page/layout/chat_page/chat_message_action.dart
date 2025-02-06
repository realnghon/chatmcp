import 'package:flutter/material.dart';
import 'package:ChatMcp/llm/model.dart';
import 'package:flutter/services.dart';
import 'package:ChatMcp/utils/color.dart';

class MessageActions extends StatelessWidget {
  final List<ChatMessage> messages;
  final Function(ChatMessage) onRetry;
  final Function(String messageId) onSwitch;

  const MessageActions({
    super.key,
    required this.messages,
    required this.onRetry,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: messages.last.content ?? '',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已复制到剪贴板'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            iconSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            icon: const Icon(Icons.refresh),
            onPressed: () {
              onRetry(messages.last);
            },
          ),
          if (messages.first.brotherMessageIds != null &&
              messages.first.brotherMessageIds!.isNotEmpty)
            _buildBranchSwitchWidget(messages),
        ],
      ),
    );
  }

  Widget _buildBranchSwitchWidget(List<ChatMessage> messages) {
    int index =
        messages.first.brotherMessageIds!.indexOf(messages.first.messageId) + 1;
    int length = messages.first.brotherMessageIds!.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 14,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ),
          icon: Icon(
            Icons.arrow_back_ios,
            size: 12,
            color: index == 1 ? AppColors.grey[400] : null,
          ),
          onPressed: index == 1
              ? null
              : () {
                  onSwitch(messages.first.brotherMessageIds![index - 2]);
                },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            '$index/$length',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey[600],
            ),
          ),
        ),
        IconButton(
          iconSize: 14,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ),
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: index == length ? AppColors.grey[400] : null,
          ),
          onPressed: index == length
              ? null
              : () {
                  onSwitch(messages.first.brotherMessageIds![index]);
                },
        ),
      ],
    );
  }
}
