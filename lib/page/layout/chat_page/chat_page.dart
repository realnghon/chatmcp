import 'dart:typed_data';

import 'package:chatmcp/llm/prompt.dart';
import 'package:chatmcp/utils/platform.dart';
import 'package:flutter/material.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:chatmcp/llm/llm_factory.dart';
import 'package:chatmcp/llm/base_llm_client.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'input_area.dart';
import 'package:chatmcp/provider/provider_manager.dart';
import 'package:chatmcp/utils/file_content.dart';
import 'package:chatmcp/dao/chat.dart';
import 'package:uuid/uuid.dart';
import 'chat_message_list.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/widgets/widgets_to_image/utils.dart';
import 'chat_message_to_image.dart';
import 'package:chatmcp/tool/tools.dart';
import 'package:chatmcp/utils/event_bus.dart';
import 'chat_code_preview.dart';
import 'package:chatmcp/generated/app_localizations.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // 状态变量
  bool _showCodePreview = false;
  Chat? _chat;
  List<ChatMessage> _messages = [];
  bool _isComposing = false; // 是否正在输入
  BaseLLMClient? _llmClient;
  String _currentResponse = '';
  bool _isLoading = false; // 是否正在加载
  String _errorMessage = ''; // 错误信息
  String _parentMessageId = ''; // 父消息ID
  bool _isCancelled = false; // 是否取消

  WidgetsToImageController toImagecontroller = WidgetsToImageController();
  // to save image bytes of widget
  Uint8List? bytes;

  bool mobile = kIsMobile;

  @override
  void initState() {
    super.initState();
    _initializeState();
    on<CodePreviewEvent>(_onArtifactEvent);
    on<ShareEvent>(_handleShare);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMobile() != mobile) {
        setState(() {
          mobile = _isMobile();
          _showCodePreview = false;
        });
      }
      if (!mobile && showModalCodePreview) {
        setState(() {
          Navigator.pop(context);
          showModalCodePreview = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  // 初始化相关方法
  void _initializeState() {
    _initializeLLMClient();
    _addListeners();
    _initializeHistoryMessages();
  }

  void _addListeners() {
    ProviderManager.settingsProvider.addListener(_onSettingsChanged);
    ProviderManager.chatModelProvider.addListener(_initializeLLMClient);
    ProviderManager.chatProvider.addListener(_onChatProviderChanged);
  }

  void _removeListeners() {
    ProviderManager.settingsProvider.removeListener(_onSettingsChanged);
    ProviderManager.chatProvider.removeListener(_onChatProviderChanged);
  }

  void _initializeLLMClient() {
    _llmClient = LLMFactoryHelper.createFromModel(
        ProviderManager.chatModelProvider.currentModel);
    setState(() {});
  }

  void _onSettingsChanged() {
    _initializeLLMClient();
  }

  void _onChatProviderChanged() {
    _initializeHistoryMessages();
  }

  List<ChatMessage> _allMessages = [];

  Future<List<ChatMessage>> _getHistoryTreeMessages() async {
    final activeChat = ProviderManager.chatProvider.activeChat;
    if (activeChat == null) return [];

    Map<String, List<String>> messageMap = {};

    final messages = await activeChat.getChatMessages();

    for (var message in messages) {
      if (message.role == MessageRole.user) {
        continue;
      }
      if (messageMap[message.parentMessageId] == null) {
        messageMap[message.parentMessageId] = [];
      }

      messageMap[message.parentMessageId]?.add(message.messageId);
    }

    for (var message in messages) {
      final brotherIds = messageMap[message.messageId] ?? [];

      if (brotherIds.length > 1) {
        int index =
            messages.indexWhere((m) => m.messageId == message.messageId);
        if (index != -1) {
          messages[index].childMessageIds ??= brotherIds;
        }

        for (var brotherId in brotherIds) {
          final index = messages.indexWhere((m) => m.messageId == brotherId);
          if (index != -1) {
            messages[index].brotherMessageIds ??= brotherIds;
          }
        }
      }
    }

    setState(() {
      _allMessages = messages;
    });

    // print('messages:\n${const JsonEncoder.withIndent('  ').convert(messages)}');

    final lastMessage = messages.last;
    return _getTreeMessages(lastMessage.messageId, messages);
  }

  List<ChatMessage> _getTreeMessages(
      String messageId, List<ChatMessage> messages) {
    final lastMessage = messages.firstWhere((m) => m.messageId == messageId);
    List<ChatMessage> treeMessages = [];

    ChatMessage? currentMessage = lastMessage;
    while (currentMessage != null) {
      if (currentMessage.role != MessageRole.user) {
        final childMessageIds = currentMessage.childMessageIds;
        if (childMessageIds != null && childMessageIds.isNotEmpty) {
          for (var childId in childMessageIds.reversed) {
            final childMessage = messages.firstWhere(
              (m) => m.messageId == childId,
              orElse: () => ChatMessage(content: '', role: MessageRole.user),
            );
            if (treeMessages
                .any((m) => m.messageId == childMessage.messageId)) {
              continue;
            }
            treeMessages.insert(0, childMessage);
          }
        }
      }

      treeMessages.insert(0, currentMessage);

      final parentId = currentMessage.parentMessageId;
      if (parentId == null || parentId.isEmpty) break;

      currentMessage = messages.firstWhere(
        (m) => m.messageId == parentId,
        orElse: () => ChatMessage(
          messageId: '',
          content: '',
          role: MessageRole.user,
          parentMessageId: '',
        ),
      );

      if (currentMessage.messageId.isEmpty) break;
    }

    // print('messageId: ${lastMessage.messageId}');

    ChatMessage? nextMessage = messages
        .where((m) => m.role == MessageRole.user)
        .firstWhere(
          (m) => m.parentMessageId == lastMessage.messageId,
          orElse: () =>
              ChatMessage(messageId: '', content: '', role: MessageRole.user),
        );

    // print(
    // 'nextMessage:\n${const JsonEncoder.withIndent('  ').convert(nextMessage)}');

    while (nextMessage != null && nextMessage.messageId.isNotEmpty) {
      if (!treeMessages.any((m) => m.messageId == nextMessage!.messageId)) {
        treeMessages.add(nextMessage);
      }
      final childMessageIds = nextMessage.childMessageIds;
      if (childMessageIds != null && childMessageIds.isNotEmpty) {
        for (var childId in childMessageIds) {
          final childMessage = messages.firstWhere(
            (m) => m.messageId == childId,
            orElse: () =>
                ChatMessage(messageId: '', content: '', role: MessageRole.user),
          );
          if (treeMessages.any((m) => m.messageId == childMessage.messageId)) {
            continue;
          }
          treeMessages.add(childMessage);
        }
      }

      nextMessage = messages.firstWhere(
        (m) => m.parentMessageId == nextMessage!.messageId,
        orElse: () =>
            ChatMessage(messageId: '', content: '', role: MessageRole.user),
      );
    }

    // print(
    //     'treeMessages:\n${const JsonEncoder.withIndent('  ').convert(treeMessages)}');
    return treeMessages;
  }

  // 消息处理相关方法
  Future<void> _initializeHistoryMessages() async {
    final activeChat = ProviderManager.chatProvider.activeChat;
    setState(() {
      _showCodePreview = false;
    });
    if (activeChat == null) {
      setState(() {
        _messages = [];
        _chat = null;
        _parentMessageId = '';
      });
      return;
    }
    if (_chat?.id != activeChat.id) {
      final messages = await _getHistoryTreeMessages();
      // 找到最后一条用户消息的索引
      final lastUserIndex =
          messages.lastIndexWhere((m) => m.role == MessageRole.user);
      String parentId = '';

      // 如果找到用户消息，且其后有助手消息，则使用助手消息的ID
      if (lastUserIndex != -1 && lastUserIndex + 1 < messages.length) {
        parentId = messages[lastUserIndex + 1].messageId;
      } else if (messages.isNotEmpty) {
        // 如果没有找到合适的消息，使用最后一条消息的ID
        parentId = messages.last.messageId;
      }

      setState(() {
        _messages = messages;
        _chat = activeChat;
        _parentMessageId = parentId;
      });
    }
  }

  // UI 构建相关方法
  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Expanded(
        child: Container(
          color: AppColors.transparent,
          child: Center(
            child: Text(
              l10n.welcomeMessage,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: MessageList(
        messages: _isLoading
            ? [
                ..._messages,
                ChatMessage(content: '', role: MessageRole.loading)
              ]
            : _messages.toList(),
        onRetry: _onRetry,
        onSwitch: _onSwitch,
      ),
    );
  }

  void _onSwitch(String messageId) {
    final messages = _getTreeMessages(messageId, _allMessages);
    setState(() {
      _messages = messages;
    });
  }

  // 消息处理相关方法
  void _handleTextChanged(String text) {
    setState(() {
      _isComposing = text.isNotEmpty;
    });
  }

  // 工具调用
  Future<void> _handleToolCall(String text) async {
    var tools = {
      "local": await getTools(),
    };

    if (kIsDesktop) {
      final mcpServerProvider = ProviderManager.mcpServerProvider;
      tools = {
        ...tools,
        ...await mcpServerProvider.getTools(),
      };
    }
    Logger.root.info(
        'all tools:\n${const JsonEncoder.withIndent('  ').convert(tools)}');

    if (tools.isEmpty) return;

    final toolCall = await _llmClient!.checkToolCall(text, tools);
    if (!toolCall['need_tool_call']) return;

    await _processMcpToolCall(toolCall, tools);
  }

  Future<void> _processMcpToolCall(
      Map<String, dynamic> toolCall, Map<String, dynamic> tools) async {
    final toolName = toolCall['tool_calls'][0]['name'];
    final toolArguments =
        toolCall['tool_calls'][0]['arguments'] as Map<String, dynamic>;

    String? clientName = _findClientName(tools, toolName);
    if (clientName == null) return;

    _addToolCallMessage(clientName, toolName, toolArguments);
    await _sendToolCallAndProcessResponse(clientName, toolName, toolArguments);
  }

  String? _findClientName(Map<String, dynamic> tools, String toolName) {
    for (var entry in tools.entries) {
      final clientTools = entry.value;
      if (clientTools.any((tool) => tool['name'] == toolName)) {
        return entry.key;
      }
    }
    return null;
  }

  void _addToolCallMessage(
      String clientName, String toolName, Map<String, dynamic> toolArguments) {
    setState(() {
      _messages.add(ChatMessage(
          content: null,
          role: MessageRole.assistant,
          parentMessageId: _parentMessageId,
          mcpServerName: clientName,
          toolCalls: [
            {
              'id': "call_$toolName",
              'type': 'function',
              'function': {
                'name': toolName,
                'arguments': jsonEncode(toolArguments)
              }
            }
          ]));
    });
  }

  Future<dynamic> _processLocalToolCall(
      String toolName, Map<String, dynamic> toolArguments) async {
    return await useTool(toolName, toolArguments);
  }

  Future<void> _sendToolCallAndProcessResponse(String clientName,
      String toolName, Map<String, dynamic> toolArguments) async {
    if (clientName == "local") {
      final response = await _processLocalToolCall(toolName, toolArguments);

      setState(() {
        print(
            'response: $response, type: ${response.runtimeType}, ${response.toString()}');
        _currentResponse = response.toString();
        if (_currentResponse.isNotEmpty) {
          _messages.add(ChatMessage(
            content: _currentResponse,
            role: MessageRole.tool,
            mcpServerName: clientName,
            name: toolName,
            toolCallId: 'call_$toolName',
            parentMessageId: _parentMessageId,
          ));
        }
      });
      return;
    }

    final mcpClient = ProviderManager.mcpServerProvider.getClient(clientName);
    if (mcpClient == null) return;

    final response = await mcpClient.sendToolCall(
      name: toolName,
      arguments: toolArguments,
    );

    setState(() {
      _currentResponse = response.result['content'].toString();
      if (_currentResponse.isNotEmpty) {
        _messages.add(ChatMessage(
          content: _currentResponse,
          role: MessageRole.tool,
          mcpServerName: clientName,
          name: toolName,
          toolCallId: 'call_$toolName',
          parentMessageId: _parentMessageId,
        ));
      }
    });
  }

  ChatMessage? _findUserMessage(ChatMessage message) {
    final parentMessage = _messages.firstWhere(
      (m) => m.messageId == message.parentMessageId,
      orElse: () =>
          ChatMessage(messageId: '', content: '', role: MessageRole.user),
    );

    if (parentMessage.messageId.isEmpty) return null;

    if (parentMessage.role != MessageRole.user) {
      return _findUserMessage(parentMessage);
    }

    return parentMessage;
  }

  Future<void> _onRetry(ChatMessage message) async {
    final userMessage = _findUserMessage(message);
    if (userMessage == null) return;

    // 找到从开始到 userMessage 的所有消息
    final messageIndex = _messages.indexOf(userMessage);
    if (messageIndex == -1) return;

    final previousMessages = _messages.sublist(0, messageIndex + 1);

    // 移除从 userMessage 之后的所有消息
    setState(() {
      _messages = previousMessages;
      _parentMessageId = userMessage.messageId;
      _isLoading = true;
    });

    try {
      await _handleToolCall(userMessage.content ?? '');
      await _processLLMResponse();
      await _updateChat();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 消息提交处理
  Future<void> _handleSubmitted(SubmitData data) async {
    setState(() {
      _isCancelled = false;
    });
    final files = data.files.map((file) => platformFileToFile(file)).toList();

    _addUserMessage(data.text, files);

    try {
      await _handleToolCall(data.text);
      await _processLLMResponse();
      await _updateChat();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addUserMessage(String text, List<File> files) {
    setState(() {
      _isLoading = true;
      _isComposing = false;
      final msgId = Uuid().v4();
      _messages.add(
        ChatMessage(
          messageId: msgId,
          parentMessageId: _parentMessageId,
          content: text.replaceAll('\n', '\n\n'),
          role: MessageRole.user,
          files: files,
        ),
      );
      _parentMessageId = msgId;
    });
  }

  String _getSystemPrompt() {
    final systemPrompt =
        ProviderManager.settingsProvider.generalSetting.systemPrompt;
    if (ProviderManager.settingsProvider.generalSetting.enableArtifacts) {
      return "$systemPrompt\n\n$artifactPrompt";
    }
    return systemPrompt;
  }

  Future<void> _processLLMResponse() async {
    final List<ChatMessage> messageList = _prepareMessageList();
    Logger.root.info('start process llm response');

    final modelSetting = ProviderManager.settingsProvider.modelSetting;

    final stream = _llmClient!.chatStreamCompletion(CompletionRequest(
      model: ProviderManager.chatModelProvider.currentModel.name,
      messages: [
        ChatMessage(
          content: _getSystemPrompt(),
          role: MessageRole.system,
        ),
        ...messageList,
      ],
      modelSetting: modelSetting,
    ));

    _initializeAssistantResponse();
    await _processResponseStream(stream);
    Logger.root.info('end process llm response');
  }

  List<ChatMessage> _prepareMessageList() {
    final List<ChatMessage> messageList = _messages
        .map((m) => ChatMessage(
              role: m.role,
              content: m.content,
              toolCallId: m.toolCallId,
              name: m.name,
              toolCalls: m.toolCalls,
              files: m.files,
            ))
        .toList();

    _reorderMessages(messageList);
    return messageList;
  }

  void _reorderMessages(List<ChatMessage> messageList) {
    for (int i = 0; i < messageList.length - 1; i++) {
      if (messageList[i].role == MessageRole.user &&
          messageList[i + 1].role == MessageRole.tool) {
        final temp = messageList[i];
        messageList[i] = messageList[i + 1];
        messageList[i + 1] = temp;
        i++;
      }
    }
  }

  void _initializeAssistantResponse() {
    setState(() {
      _currentResponse = '';
      _messages.add(
        ChatMessage(
          content: _currentResponse,
          role: MessageRole.assistant,
          parentMessageId: _parentMessageId,
        ),
      );
    });
  }

  Future<void> _processResponseStream(Stream<LLMResponse> stream) async {
    await for (final chunk in stream) {
      if (_isCancelled) break;
      setState(() {
        _currentResponse += chunk.content ?? '';
        _messages.last = ChatMessage(
          content: _currentResponse,
          role: MessageRole.assistant,
          parentMessageId: _parentMessageId,
        );
      });
    }
    _isCancelled = false;
  }

  Future<void> _updateChat() async {
    if (ProviderManager.chatProvider.activeChat == null) {
      await _createNewChat();
    } else {
      await _updateExistingChat();
    }
  }

  Future<void> _createNewChat() async {
    String title =
        await _llmClient!.genTitle([_messages.first, _messages.last]);
    await ProviderManager.chatProvider
        .createChat(Chat(title: title), _handleParentMessageId(_messages));
    Logger.root.info('create new chat: $title');
  }

  // messages parentMessageId 处理
  List<ChatMessage> _handleParentMessageId(List<ChatMessage> messages) {
    if (messages.isEmpty) return [];

    // 找到最后一条用户消息的索引
    int lastUserIndex =
        messages.lastIndexWhere((m) => m.role == MessageRole.user);
    if (lastUserIndex == -1) return messages;

    // 获取从最后一条用户消息开始的所有消息
    List<ChatMessage> relevantMessages = messages.sublist(lastUserIndex);

    // 如果消息数大于2，重置第二条之后消息的parentMessageId
    if (relevantMessages.length > 2) {
      String secondMessageId = relevantMessages[1].messageId;
      for (int i = 2; i < relevantMessages.length; i++) {
        relevantMessages[i] = relevantMessages[i].copyWith(
          parentMessageId: secondMessageId,
        );
      }
    }

    return relevantMessages;
  }

  Future<void> _updateExistingChat() async {
    final activeChat = ProviderManager.chatProvider.activeChat!;
    await ProviderManager.chatProvider.updateChat(Chat(
      id: activeChat.id!,
      title: activeChat.title,
      createdAt: activeChat.createdAt,
      updatedAt: DateTime.now(),
    ));

    await ProviderManager.chatProvider
        .addChatMessage(activeChat.id!, _handleParentMessageId(_messages));
  }

  void _handleError(dynamic error, StackTrace stackTrace) {
    setState(() {
      _errorMessage = error.toString();
    });

    Logger.root.severe(error, stackTrace);

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.red),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.error),
              ],
            ),
            content: SingleChildScrollView(
              child: SelectableText(
                error.toString(),
                style: const TextStyle(color: AppColors.red),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          );
        },
      );
    }
  }

  // 处理分享事件
  Future<void> _handleShare(ShareEvent event) async {
    if (_messages.isEmpty) return;
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      if (kIsMobile) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListViewToImageScreen(messages: _messages),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => ListViewToImageScreen(messages: _messages),
        );
      }
    }
  }

  bool _isMobile() {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return height > width;
  }

  void _handleCancel() {
    setState(() {
      _isComposing = false;
      _isLoading = false;
      _isCancelled = true;
    });
  }

  Widget _buildBody() {
    if (mobile) {
      return Column(
        children: [
          _buildMessageList(),
          InputArea(
            disabled: _isLoading,
            isComposing: _isComposing,
            onTextChanged: _handleTextChanged,
            onSubmitted: _handleSubmitted,
            onCancel: _handleCancel,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildMessageList(),
              InputArea(
                disabled: _isLoading,
                isComposing: _isComposing,
                onTextChanged: _handleTextChanged,
                onSubmitted: _handleSubmitted,
                onCancel: _handleCancel,
              ),
            ],
          ),
        ),
        if (!mobile && _showCodePreview)
          Expanded(
            flex: 1,
            child: _codePreviewEvent != null
                ? ChatCodePreview(
                    codePreviewEvent: _codePreviewEvent!,
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  CodePreviewEvent? _codePreviewEvent;

  void _onArtifactEvent(CodePreviewEvent event) {
    _toggleCodePreview();
    setState(() {
      _codePreviewEvent = event;
    });
  }

  bool showModalCodePreview = false;
  void _showMobileCodePreview() {
    setState(() {
      showModalCodePreview = true;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: _codePreviewEvent != null
                          ? ChatCodePreview(
                              codePreviewEvent: _codePreviewEvent!,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _toggleCodePreview() {
    if (_isMobile()) {
      _showMobileCodePreview();
      if (_showCodePreview) {
        setState(() {
          _showCodePreview = false;
        });
      }
    } else {
      setState(() {
        _showCodePreview = !_showCodePreview;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }
}
