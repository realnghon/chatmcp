import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './chat_page/chat_page.dart';
import './chat_history.dart';
import './widgets/top_toolbar.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import 'package:ChatMcp/provider/chat_model_provider.dart';

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  bool hideChatHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProviderManager.chatModelProvider.loadAvailableModels();
    });
  }

  void _toggleChatHistory() {
    setState(() {
      hideChatHistory = !hideChatHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatModelProvider>(
      builder: (context, chatModelProvider, child) {
        return Scaffold(
          body: Row(
            children: [
              if (!hideChatHistory)
                Container(
                  width: 250,
                  color: Colors.grey[200],
                  child: ChatHistoryPanel(
                    onToggle: _toggleChatHistory,
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    TopToolbar(
                      hideChatHistory: hideChatHistory,
                      onToggleChatHistory: _toggleChatHistory,
                    ),
                    const Expanded(
                      child: ChatPage(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
