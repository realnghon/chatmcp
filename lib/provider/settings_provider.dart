import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'chat_model_provider.dart';

class KeysSetting {
  String apiKey;
  String apiEndpoint;

  KeysSetting({
    required this.apiKey,
    required this.apiEndpoint,
  });

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'apiEndpoint': apiEndpoint,
    };
  }

  factory KeysSetting.fromJson(Map<String, dynamic> json) {
    return KeysSetting(
      apiKey: json['apiKey'] as String,
      apiEndpoint: json['apiEndpoint'] as String,
    );
  }
}

var defaultSystemPrompt =
    '''You are an intelligent and helpful AI assistant. Please:
1. Provide clear and concise responses
2. If you're not sure about something, please say so
3. When appropriate, provide examples to illustrate your points
4. If a user messages you in a specific language, respond in that language
5. Format responses using markdown when helpful
6. Use mermaid to generate diagrams''';

class GeneralSetting {
  String theme;
  bool showAssistantAvatar = true;
  bool showUserAvatar = true;
  String systemPrompt;

  GeneralSetting({
    required this.theme,
    this.showAssistantAvatar = true,
    this.showUserAvatar = true,
    this.systemPrompt = 'You are a helpful assistant.',
  });

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'showAssistantAvatar': showAssistantAvatar,
      'showUserAvatar': showUserAvatar,
      'systemPrompt': systemPrompt,
    };
  }

  factory GeneralSetting.fromJson(Map<String, dynamic> json) {
    return GeneralSetting(
      theme: json['theme'] as String? ?? 'light',
      showAssistantAvatar: json['showAssistantAvatar'] as bool? ?? true,
      showUserAvatar: json['showUserAvatar'] as bool? ?? true,
      systemPrompt: json['systemPrompt'] as String? ?? defaultSystemPrompt,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  factory SettingsProvider() => _instance;
  SettingsProvider._internal();

  Map<String, KeysSetting> _apiSettings = {};

  GeneralSetting _generalSetting = GeneralSetting(
    theme: 'light',
    systemPrompt: defaultSystemPrompt,
  );

  Map<String, KeysSetting> get apiSettings => _apiSettings;

  GeneralSetting get generalSetting => _generalSetting;

  int sandboxServerPort = 0;

  Future<void> updateSandboxServerPort({required int port}) async {
    sandboxServerPort = port;
    notifyListeners();
  }

  Future<Map<String, KeysSetting>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString('apiSettings');

    if (settingsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(settingsJson);
      _apiSettings = decoded.map((key, value) =>
          MapEntry(key, KeysSetting.fromJson(value as Map<String, dynamic>)));
    }

    final String? generalSettingsJson = prefs.getString('generalSettings');
    if (generalSettingsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(generalSettingsJson);
      _generalSetting = GeneralSetting.fromJson(decoded);
    }

    notifyListeners();

    return _apiSettings;
  }

  Future<void> updateApiSettings({
    required Map<String, KeysSetting> apiSettings,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _apiSettings = apiSettings;

    final encodedSettings =
        apiSettings.map((key, value) => MapEntry(key, value.toJson()));

    await prefs.setString('apiSettings', jsonEncode(encodedSettings));

    await ChatModelProvider().loadAvailableModels();

    notifyListeners();
  }

  Future<void> updateGeneralSettings({
    required String theme,
    required bool showAssistantAvatar,
    required bool showUserAvatar,
    required String systemPrompt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _generalSetting = GeneralSetting(
      theme: theme,
      showAssistantAvatar: showAssistantAvatar,
      showUserAvatar: showUserAvatar,
      systemPrompt: systemPrompt,
    );
    await prefs.setString(
        'generalSettings', jsonEncode(_generalSetting.toJson()));
    notifyListeners();
  }
}
