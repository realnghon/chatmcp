import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'provider_manager.dart';
import 'package:logging/logging.dart';

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
  bool showAssistantAvatar = false;
  bool showUserAvatar = false;
  bool enableArtifacts = true;
  String systemPrompt;
  String locale;

  GeneralSetting({
    required this.theme,
    this.showAssistantAvatar = false,
    this.showUserAvatar = false,
    this.enableArtifacts = true,
    this.systemPrompt = 'You are a helpful assistant.',
    this.locale = 'en',
  });

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'showAssistantAvatar': showAssistantAvatar,
      'showUserAvatar': showUserAvatar,
      'enableArtifacts': enableArtifacts,
      'systemPrompt': systemPrompt,
      'locale': locale,
    };
  }

  factory GeneralSetting.fromJson(Map<String, dynamic> json) {
    return GeneralSetting(
      theme: json['theme'] as String? ?? 'light',
      showAssistantAvatar: json['showAssistantAvatar'] as bool? ?? true,
      showUserAvatar: json['showUserAvatar'] as bool? ?? true,
      enableArtifacts: json['enableArtifacts'] as bool? ?? false,
      systemPrompt: json['systemPrompt'] as String? ?? defaultSystemPrompt,
      locale: json['locale'] as String? ?? 'en',
    );
  }
}

class ChatSetting {
  double temperature = 1.0;
  int? maxTokens;
  double topP = 1.0;
  double frequencyPenalty = 0.0;
  double presencePenalty = 0.0;

  ChatSetting({
    this.temperature = 1.0,
    this.maxTokens,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'maxTokens': maxTokens,
      'topP': topP,
      'frequencyPenalty': frequencyPenalty,
      'presencePenalty': presencePenalty,
    };
  }

  factory ChatSetting.fromJson(Map<String, dynamic> json) {
    return ChatSetting(
      temperature: json['temperature'] as double? ?? 1.0,
      maxTokens: json['maxTokens'] == null ? null : json['maxTokens'] as int,
      topP: json['topP'] as double? ?? 1.0,
      frequencyPenalty: json['frequencyPenalty'] as double? ?? 0.0,
      presencePenalty: json['presencePenalty'] as double? ?? 0.0,
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

  ChatSetting _modelSetting = ChatSetting();

  Map<String, KeysSetting> get apiSettings => _apiSettings;

  GeneralSetting get generalSetting => _generalSetting;

  ChatSetting get modelSetting => _modelSetting;

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

    final String? modelSettingsJson = prefs.getString('modelSettings');
    if (modelSettingsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(modelSettingsJson);
      _modelSetting = ChatSetting.fromJson(decoded);
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
    Logger.root.info('updateApiSettings: $encodedSettings');

    await ProviderManager.chatModelProvider.loadAvailableModels();
    Logger.root.info('updateApiSettings: success');

    notifyListeners();
  }

  Future<void> updateGeneralSettings({
    required String theme,
    required bool showAssistantAvatar,
    required bool showUserAvatar,
    required String systemPrompt,
    required bool enableArtifacts,
    required String locale,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _generalSetting = GeneralSetting(
      theme: theme,
      showAssistantAvatar: showAssistantAvatar,
      showUserAvatar: showUserAvatar,
      systemPrompt: systemPrompt,
      enableArtifacts: enableArtifacts,
      locale: locale,
    );
    await prefs.setString(
        'generalSettings', jsonEncode(_generalSetting.toJson()));
    notifyListeners();
  }

  Future<void> updateModelSettings({
    required double temperature,
    required int? maxTokens,
    required double topP,
    required double frequencyPenalty,
    required double presencePenalty,
  }) async {
    _modelSetting = ChatSetting(
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('modelSettings', jsonEncode(_modelSetting.toJson()));
    notifyListeners();
  }

  Future<void> resetModelSettings() async {
    _modelSetting = ChatSetting();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('modelSettings', jsonEncode(_modelSetting.toJson()));
    notifyListeners();
  }
}
