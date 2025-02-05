import 'package:ChatMcp/utils/platform.dart';
import 'package:flutter/material.dart';
import 'package:ChatMcp/llm/model.dart';
import 'package:ChatMcp/llm/llm_factory.dart';
import 'package:ChatMcp/llm/base_llm_client.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'input_area.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import 'package:ChatMcp/utils/file_content.dart';
import 'package:ChatMcp/dao/chat.dart';
import 'package:uuid/uuid.dart';
import 'chat_message_list.dart';
import 'package:ChatMcp/utils/color.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // 状态变量
  Chat? _chat;
  List<ChatMessage> _messages = [];
  bool _isComposing = false;
  BaseLLMClient? _llmClient;
  String _currentResponse = '';
  bool _isLoading = false;
  String _errorMessage = '';
  String _parentMessageId = '';

  @override
  void initState() {
    super.initState();
    _initializeState();
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

  // 消息处理相关方法
  Future<void> _initializeHistoryMessages() async {
    final activeChat = ProviderManager.chatProvider.activeChat;
    if (activeChat == null) {
      setState(() {
        _messages = [];
        _chat = null;
      });
      return;
    }
    if (_chat?.id != activeChat.id) {
      final messages = await activeChat.getChatMessages();
      Logger.root.info(
          'messages:\n${const JsonEncoder.withIndent('  ').convert(messages)}');

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
      return const Center(
        child: Text(
          'How can I help you today?',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.grey,
          ),
        ),
      );
    }

    return MessageList(
      key: ValueKey(_messages.length),
      messages: _isLoading
          ? [..._messages, ChatMessage(content: '', role: MessageRole.loading)]
          : _messages.toList(),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(8.0),
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: AppColors.red.shade100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.red),
          const SizedBox(width: 8.0),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: AppColors.red),
                softWrap: true,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, color: AppColors.red),
            onPressed: () => setState(() => _errorMessage = ''),
          ),
        ],
      ),
    );
  }

  // 消息处理相关方法
  void _handleTextChanged(String text) {
    setState(() {
      _isComposing = text.isNotEmpty;
    });
  }

  // MCP 服务器相关方法
  Future<void> _handleMcpServerTools(String text) async {
    if (kIsMobile) return;

    final mcpServerProvider = ProviderManager.mcpServerProvider;
    final tools = await mcpServerProvider.getTools();
    Logger.root
        .info('tools:\n${const JsonEncoder.withIndent('  ').convert(tools)}');

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
              'id': 'call_$toolName',
              'type': 'function',
              'function': {
                'name': toolName,
                'arguments': jsonEncode(toolArguments)
              }
            }
          ]));
    });
  }

  Future<void> _sendToolCallAndProcessResponse(String clientName,
      String toolName, Map<String, dynamic> toolArguments) async {
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

  // 消息提交处理
  Future<void> _handleSubmitted(SubmitData data) async {
    final files = data.files.map((file) => platformFileToFile(file)).toList();

    _addUserMessage(data.text, files);

    try {
      await _handleMcpServerTools(data.text);
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
          content: text,
          role: MessageRole.user,
          files: files,
        ),
      );
      _parentMessageId = msgId;
    });
  }

  Future<void> _processLLMResponse() async {
    final List<ChatMessage> messageList = _prepareMessageList();
    final stream = _llmClient!.chatStreamCompletion(CompletionRequest(
      model: ProviderManager.chatModelProvider.currentModel.name,
      messages: [
        ChatMessage(
          content: ProviderManager.settingsProvider.generalSetting.systemPrompt,
          role: MessageRole.assistant,
        ),
        ...messageList,
      ],
    ));

    _initializeAssistantResponse();
    await _processResponseStream(stream);
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
      setState(() {
        _currentResponse += chunk.content ?? '';
        _messages.last = ChatMessage(
          content: _currentResponse,
          role: MessageRole.assistant,
          parentMessageId: _parentMessageId,
        );
      });
    }
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
        relevantMessages[i] = ChatMessage(
          messageId: relevantMessages[i].messageId,
          content: relevantMessages[i].content,
          role: relevantMessages[i].role,
          parentMessageId: secondMessageId,
          files: relevantMessages[i].files,
          toolCalls: relevantMessages[i].toolCalls,
          toolCallId: relevantMessages[i].toolCallId,
          name: relevantMessages[i].name,
          mcpServerName: relevantMessages[i].mcpServerName,
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

    final lastFiveMessages = _messages.length <= 5
        ? _messages
        : _messages.sublist(_messages.length - 5);

    await ProviderManager.chatProvider.addChatMessage(
        activeChat.id!,
        _handleParentMessageId(
            lastFiveMessages.where((m) => m.content != null).toList()));
  }

  void _handleError(dynamic error, StackTrace stackTrace) {
    setState(() {
      _errorMessage = error.toString();
    });

    print('error: $error');
    print('stackTrace: $stackTrace');
    Logger.root.severe(error, stackTrace);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildErrorMessage(),
          InputArea(
            disabled: _isLoading,
            isComposing: _isComposing,
            onTextChanged: _handleTextChanged,
            onSubmitted: _handleSubmitted,
          ),
        ],
      ),
    );
  }
}
