import 'package:chatmcp/provider/settings_provider.dart';
import 'package:chatmcp/utils/platform.dart';
import 'package:flutter/material.dart';
import 'package:chatmcp/llm/model.dart';
import 'dart:convert';
import 'package:chatmcp/widgets/collapsible_section.dart';
import 'package:chatmcp/widgets/markdown/markit_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io' as io;
import 'package:chatmcp/utils/color.dart';
import 'chat_message_action.dart';
import 'package:chatmcp/tool/tavily.dart';
import 'package:chatmcp/generated/app_localizations.dart';

class ChatUIMessage extends StatelessWidget {
  final List<ChatMessage> messages;
  final Function(ChatMessage) onRetry;
  final Function(String messageId) onSwitch;

  const ChatUIMessage({
    super.key,
    required this.messages,
    required this.onRetry,
    required this.onSwitch,
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
                    ChatMessageContent(message: msg, onRetry: onRetry),
                  if (kIsDesktop &&
                      messages.last.role != MessageRole.loading &&
                      !isUser)
                    MessageActions(
                      messages: messages,
                      onRetry: onRetry,
                      onSwitch: onSwitch,
                    ),
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
  final Function(ChatMessage) onRetry;
  const ChatMessageContent({
    super.key,
    required this.message,
    required this.onRetry,
  });

  Widget _buildMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: message.role == MessageRole.user
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (message.role == MessageRole.loading)
          MessageBubble(
              message: ChatMessage(content: '', role: MessageRole.loading)),
        if (message.files != null && message.files!.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.files!
                  .map((file) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.getThemeColor(
                            context,
                            lightColor: AppColors.grey[200],
                            darkColor: AppColors.grey[800],
                          ),
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
                                    errorBuilder: (context, error, stackTrace) {
                                      final l10n =
                                          AppLocalizations.of(context)!;
                                      return Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.getThemeColor(
                                            context,
                                            lightColor: AppColors.grey[200],
                                            darkColor: AppColors.grey[800],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.broken_image,
                                              color: AppColors.getThemeColor(
                                                context,
                                                lightColor: AppColors.grey[600],
                                                darkColor: AppColors.grey[400],
                                              ),
                                              size: 32,
                                            ),
                                            Text(l10n.brokenImage),
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
                                  Flexible(
                                    child: Text(
                                      file.name,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return kIsDesktop
        ? _buildMessage(context)
        : GestureDetector(
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.copy_outlined),
                      title: Text(l10n.copy),
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                          text: message.content ?? '',
                        ));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.copied),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    if (message.role != MessageRole.user)
                      ListTile(
                        leading: const Icon(Icons.refresh),
                        title: Text(l10n.retry),
                        onTap: () {
                          Navigator.pop(context);
                          onRetry(message);
                        },
                      ),
                  ],
                ),
              );
            },
            child: _buildMessage(context),
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
            ? AppColors.getThemeColor(context,
                lightColor: AppColors.grey[200], darkColor: AppColors.grey[800])
            : AppColors.getThemeColor(context,
                lightColor: AppColors.grey[300],
                darkColor: AppColors.grey[900]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: message.content != null
          ? message.role == MessageRole.user
              ? Markit(data: (message.content!).trim())
              : Markit(data: (message.content!).trim())
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: CollapsibleSection(
        initiallyExpanded: false,
        title: Text(
          l10n.toolCall(message.toolCalls![0]['function']['name']),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey[600],
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

  Widget _buildContent(BuildContext context) {
    return SelectableText(message.content ?? '');
  }

  Widget _buildFactory(BuildContext context) {
    switch (message.toolCallId) {
      case 'call_web_search':
        try {
          return TavilySearchResultWidget(
              response: TavilySearchResponse.fromJson(
                  json.decode(message.content ?? '')));
        } catch (e) {
          // JSON解析失败，回退到文本显示
          return Markit(data: message.content ?? '');
        }
      case 'call_generate_image':
        try {
          final jsonData = json.decode(message.content ?? '');
          return Markit(
              data:
                  "```json\n${const JsonEncoder.withIndent('  ').convert(jsonData)}\n```");
        } catch (e) {
          return Markit(data: "```\n${message.content}\n```");
        }
      default:
        return _buildContent(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: CollapsibleSection(
        initiallyExpanded: false,
        title: Text(
          l10n.toolResult(message.toolCallId!.replaceFirst('call_', '')),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        content: _buildFactory(context),
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
      backgroundColor: AppColors.grey,
      child: Icon(
        isUser ? Icons.person : Icons.android,
        color: AppColors.white,
      ),
    );
  }
}
