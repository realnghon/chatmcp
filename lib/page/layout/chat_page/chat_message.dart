import 'package:ChatMcp/provider/settings_provider.dart';
import 'package:ChatMcp/utils/platform.dart';
import 'package:flutter/material.dart';
import 'package:ChatMcp/llm/model.dart';
import 'dart:convert';
import 'package:ChatMcp/widgets/collapsible_section.dart';
import 'package:ChatMcp/widgets/markdown/markit.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io' as io;

class ChatUIMessage extends StatelessWidget {
  final List<ChatMessage> messages;

  const ChatUIMessage({
    super.key,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox();

    final firstMsg = messages.first;
    final isUser = firstMsg.role == MessageRole.user;

    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      final showAssistantAvatar = settings.generalSetting.showAssistantAvatar;
      final showUserAvatar = settings.generalSetting.showUserAvatar;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && showAssistantAvatar) ...[
              SizedBox(
                width: 40,
                child: ChatAvatar(isUser: false),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  for (var msg in messages.length > 1
                      ? messages.where((m) => m.role != MessageRole.loading)
                      : messages)
                    ChatMessageContent(message: msg),
                  if (kIsDesktop &&
                      messages.last.role != MessageRole.loading &&
                      messages.last.role != MessageRole.error &&
                      !isUser)
                    MessageActions(message: messages.last),
                ],
              ),
            ),
            if (isUser && showUserAvatar) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: ChatAvatar(isUser: true),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class ChatMessageContent extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageContent({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('复制'),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                    text: message.content ?? '',
                  ));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已复制到剪贴板'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              if (message.role != MessageRole.user)
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('重试'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 实现重试逻辑
                  },
                ),
            ],
          ),
        );
      },
      child: Column(
        crossAxisAlignment: message.role == MessageRole.user
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (message.role == MessageRole.loading)
            MessageBubble(
                message:
                    ChatMessage(content: 'loading', role: MessageRole.loading)),
          if (message.files != null && message.files!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.files!
                    .map((file) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: file.fileType.startsWith('image')
                              ? ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.6,
                                    maxHeight: 300,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      io.File(file.path!),
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.broken_image,
                                                color: Colors.grey[600],
                                                size: 32,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.attach_file, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      file.name,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                        ))
                    .toList(),
              ),
            ),
          if ((message.role == MessageRole.user ||
                  message.role == MessageRole.assistant) &&
              message.content != null)
            MessageBubble(message: message),
          if (message.toolCalls != null && message.toolCalls!.isNotEmpty)
            ToolCallWidget(message: message),
          if (message.role == MessageRole.tool && message.toolCallId != null)
            ToolResultWidget(message: message),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.role == MessageRole.user
            ? Theme.of(context).primaryColor
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: message.role == MessageRole.user
          ? TextSelectionTheme(
              data: TextSelectionThemeData(
                selectionColor: Colors.white.withAlpha(77),
              ),
              child: SelectableText(
                message.content ?? '',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : message.content != null
              ? Markit(data: (message.content!).trim())
              : const Text(''),
    );
  }
}

class ToolCallWidget extends StatelessWidget {
  final ChatMessage message;

  const ToolCallWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: CollapsibleSection(
        title: Text(
          '${message.mcpServerName} call_${message.toolCalls![0]['function']['name']}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        content: Markit(
          data: (message.toolCalls?.isNotEmpty ?? false)
              ? [
                  '```json',
                  const JsonEncoder.withIndent('  ').convert({
                    "name": message.toolCalls![0]['function']['name'],
                    "arguments": json
                        .decode(message.toolCalls![0]['function']['arguments']),
                  }),
                  '```',
                ].join('\n')
              : '',
        ),
      ),
    );
  }
}

class ToolResultWidget extends StatelessWidget {
  final ChatMessage message;

  const ToolResultWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: CollapsibleSection(
        title: Text(
          '${message.mcpServerName} ${message.toolCallId!} result',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        content: Markit(data: (message.content ?? '').trim()),
      ),
    );
  }
}

class ChatAvatar extends StatelessWidget {
  final bool isUser;

  const ChatAvatar({
    super.key,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.grey,
      child: Icon(
        isUser ? Icons.person : Icons.android,
        color: Colors.white,
      ),
    );
  }
}

class MessageActions extends StatelessWidget {
  final ChatMessage message;

  const MessageActions({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: message.content ?? '',
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
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: 实现重试逻辑
            },
          ),
        ],
      ),
    );
  }
}
