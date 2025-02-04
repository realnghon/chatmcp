import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiSetting {
  String apiKey;
  String apiEndpoint;

  ApiSetting({
    required this.apiKey,
    required this.apiEndpoint,
  });

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'apiEndpoint': apiEndpoint,
    };
  }

  factory ApiSetting.fromJson(Map<String, dynamic> json) {
    return ApiSetting(
      apiKey: json['apiKey'] as String,
      apiEndpoint: json['apiEndpoint'] as String,
    );
  }
}

class GeneralSetting {
  String theme;
  bool showAssistantAvatar = true;
  bool showUserAvatar = true;

  GeneralSetting({
    required this.theme,
    this.showAssistantAvatar = true,
    this.showUserAvatar = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'showAssistantAvatar': showAssistantAvatar,
      'showUserAvatar': showUserAvatar,
    };
  }

  factory GeneralSetting.fromJson(Map<String, dynamic> json) {
    return GeneralSetting(
      theme: json['theme'] as String,
      showAssistantAvatar: json['showAssistantAvatar'] as bool,
      showUserAvatar: json['showUserAvatar'] as bool,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  factory SettingsProvider() => _instance;
  SettingsProvider._internal();

  Map<String, ApiSetting> _apiSettings = {};

  GeneralSetting _generalSetting = GeneralSetting(theme: 'light');

  Map<String, ApiSetting> get apiSettings => _apiSettings;

  GeneralSetting get generalSetting => _generalSetting;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString('apiSettings');

    if (settingsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(settingsJson);
      _apiSettings = decoded.map((key, value) =>
          MapEntry(key, ApiSetting.fromJson(value as Map<String, dynamic>)));
    }

    final String? generalSettingsJson = prefs.getString('generalSettings');
    if (generalSettingsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(generalSettingsJson);
      _generalSetting = GeneralSetting.fromJson(decoded);
    }

    notifyListeners();
  }

  Future<void> updateApiSettings({
    required Map<String, ApiSetting> apiSettings,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _apiSettings = apiSettings;

    final encodedSettings =
        apiSettings.map((key, value) => MapEntry(key, value.toJson()));

    await prefs.setString('apiSettings', jsonEncode(encodedSettings));

    notifyListeners();
  }

  Future<void> updateGeneralSettings({
    required String theme,
    required bool showAssistantAvatar,
    required bool showUserAvatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _generalSetting = GeneralSetting(
      theme: theme,
      showAssistantAvatar: showAssistantAvatar,
      showUserAvatar: showUserAvatar,
    );
    await prefs.setString(
        'generalSettings', jsonEncode(_generalSetting.toJson()));
    notifyListeners();
  }
}
