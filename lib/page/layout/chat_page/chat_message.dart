import 'package:flutter/material.dart';
import 'package:ChatMcp/llm/model.dart';
import 'dart:convert';
import 'package:ChatMcp/widgets/collapsible_section.dart';
import 'package:ChatMcp/widgets/markit.dart';

class ChatUIMessage extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool showAvatar;

  const ChatUIMessage({
    super.key,
    required this.messages,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox();

    final firstMsg = messages.first;
    final isUser = firstMsg.role == MessageRole.user;

    return Container(
      margin: showAvatar
          ? const EdgeInsets.symmetric(vertical: 8.0)
          : const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            SizedBox(
              width: 40,
              child: showAvatar ? _buildAvatar(false) : null,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: messages
                  .map((msg) => _buildMessageContent(context, msg))
                  .toList(),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, ChatMessage msg) {
    return Column(
      crossAxisAlignment: msg.role == MessageRole.user
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (msg.role == MessageRole.loading) const CircularProgressIndicator(),
        if ((msg.role == MessageRole.user ||
                msg.role == MessageRole.assistant) &&
            msg.content != null)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: msg.role == MessageRole.user
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: msg.role == MessageRole.user
                ? TextSelectionTheme(
                    data: TextSelectionThemeData(
                      selectionColor: Colors.white.withOpacity(0.3),
                    ),
                    child: SelectableText(
                      msg.content ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : msg.content != null
                    ? Markit(data: msg.content!)
                    : const Text(''),
          ),
        if (msg.toolCalls != null && msg.toolCalls!.isNotEmpty)
          CollapsibleSection(
            title: Text(
              '${msg.mcpServerName} call_${msg.toolCalls![0]['function']['name']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            content: Markit(
              data: (msg.toolCalls?.isNotEmpty ?? false)
                  ? [
                      '```json',
                      const JsonEncoder.withIndent('  ').convert({
                        "name": msg.toolCalls![0]['function']['name'],
                        "arguments": json
                            .decode(msg.toolCalls![0]['function']['arguments']),
                      }),
                      '```',
                    ].join('\n')
                  : '',
            ),
          ),
        if (msg.role == MessageRole.tool && msg.toolCallId != null)
          CollapsibleSection(
            title: Text(
              '${msg.mcpServerName} ${msg.toolCallId!} result',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            content: Markit(data: msg.content ?? ''),
          ),
      ],
    );
  }

  Widget _buildAvatar(bool isUser) {
    if (isUser) {
      return Container();
    }
    return CircleAvatar(
      backgroundColor: Colors.grey,
      child: Icon(
        isUser ? Icons.person : Icons.android,
        color: Colors.white,
      ),
    );
  }
}
