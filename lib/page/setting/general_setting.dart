import 'package:chatmcp/provider/provider_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/generated/app_localizations.dart';

class GeneralSettings extends StatefulWidget {
  const GeneralSettings({super.key});

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withAlpha(200),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      // 主题设置卡片
                      _buildThemeCard(context),
                      // 语言设置卡片
                      _buildLocaleCard(context),
                      // 头像显示设置卡片
                      _buildAvatarCard(context),
                      // System Prompt 设置卡片
                      _buildSystemPromptCard(context),
                      // 特性设置卡片
                      _buildFeatureCard(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocaleCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.languageSettings,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(l10n.language),
                  trailing: DropdownButton<String>(
                    value: settings.generalSetting.locale,
                    items: const [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'zh',
                        child: Text('中文'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        settings.updateGeneralSettings(
                          theme: settings.generalSetting.theme,
                          showAssistantAvatar:
                              settings.generalSetting.showAssistantAvatar,
                          showUserAvatar:
                              settings.generalSetting.showUserAvatar,
                          systemPrompt: settings.generalSetting.systemPrompt,
                          enableArtifacts:
                              settings.generalSetting.enableArtifacts,
                          locale: value,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.extension, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.featureSettings,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(l10n.enableArtifacts),
                  subtitle: Text(l10n.enableArtifactsDescription),
                  value: settings.generalSetting.enableArtifacts,
                  onChanged: (bool value) {
                    settings.updateGeneralSettings(
                      theme: settings.generalSetting.theme,
                      showAssistantAvatar:
                          settings.generalSetting.showAssistantAvatar,
                      showUserAvatar: settings.generalSetting.showUserAvatar,
                      systemPrompt: settings.generalSetting.systemPrompt,
                      enableArtifacts: value,
                      locale: ProviderManager
                          .settingsProvider.generalSetting.locale,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.themeSettings,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: settings.generalSetting.theme,
                  decoration: InputDecoration(
                    // labelText: 'Theme',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.color_lens),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'light',
                      child: Text(l10n.lightTheme),
                    ),
                    DropdownMenuItem(
                      value: 'dark',
                      child: Text(l10n.darkTheme),
                    ),
                    DropdownMenuItem(
                      value: 'system',
                      child: Text(l10n.followSystem),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.updateGeneralSettings(
                        theme: value,
                        showAssistantAvatar:
                            settings.generalSetting.showAssistantAvatar,
                        showUserAvatar: settings.generalSetting.showUserAvatar,
                        systemPrompt: settings.generalSetting.systemPrompt,
                        enableArtifacts:
                            settings.generalSetting.enableArtifacts,
                        locale: settings.generalSetting.locale,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.face, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.showAvatar,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(l10n.showAssistantAvatar),
                  subtitle: Text(l10n.showAssistantAvatarDescription),
                  value: settings.generalSetting.showAssistantAvatar,
                  onChanged: (bool value) {
                    settings.updateGeneralSettings(
                      theme: settings.generalSetting.theme,
                      showAssistantAvatar: value,
                      showUserAvatar: settings.generalSetting.showUserAvatar,
                      systemPrompt: settings.generalSetting.systemPrompt,
                      enableArtifacts: settings.generalSetting.enableArtifacts,
                      locale: settings.generalSetting.locale,
                    );
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(l10n.showUserAvatar),
                  subtitle: Text(l10n.showUserAvatarDescription),
                  value: settings.generalSetting.showUserAvatar,
                  onChanged: (bool value) {
                    settings.updateGeneralSettings(
                      theme: settings.generalSetting.theme,
                      showAssistantAvatar:
                          settings.generalSetting.showAssistantAvatar,
                      showUserAvatar: value,
                      systemPrompt: settings.generalSetting.systemPrompt,
                      enableArtifacts: settings.generalSetting.enableArtifacts,
                      locale: settings.generalSetting.locale,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemPromptCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.systemPrompt,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: settings.generalSetting.systemPrompt,
                  decoration: InputDecoration(
                    // labelText: 'System Prompt',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  onChanged: (value) {
                    settings.updateGeneralSettings(
                      theme: settings.generalSetting.theme,
                      showAssistantAvatar:
                          settings.generalSetting.showAssistantAvatar,
                      showUserAvatar: settings.generalSetting.showUserAvatar,
                      systemPrompt: value,
                      enableArtifacts: settings.generalSetting.enableArtifacts,
                      locale: settings.generalSetting.locale,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.systemPromptDescription,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
