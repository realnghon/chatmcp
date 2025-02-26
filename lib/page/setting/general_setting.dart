import 'package:chatmcp/provider/provider_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(height: 20),
                      _buildThemeCard(context),
                      _buildLocaleCard(context),
                      _buildAvatarCard(context),
                      _buildSystemPromptCard(context),
                      _buildFeatureCard(context),
                      const SizedBox(height: 20),
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

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocaleCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                context, l10n.languageSettings, CupertinoIcons.globe),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              ),
              child: ListTile(
                title: Text(
                  l10n.language,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: DropdownButton<String>(
                  value: settings.generalSetting.locale,
                  underline: const SizedBox(),
                  icon: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(50),
                  ),
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
                        showUserAvatar: settings.generalSetting.showUserAvatar,
                        systemPrompt: settings.generalSetting.systemPrompt,
                        enableArtifacts:
                            settings.generalSetting.enableArtifacts,
                        locale: value,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, l10n.featureSettings,
                CupertinoIcons.square_stack_3d_up),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              ),
              child: SwitchListTile(
                title: Text(
                  l10n.enableArtifacts,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  l10n.enableArtifactsDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(60),
                  ),
                ),
                value: settings.generalSetting.enableArtifacts,
                onChanged: (bool value) {
                  settings.updateGeneralSettings(
                    theme: settings.generalSetting.theme,
                    showAssistantAvatar:
                        settings.generalSetting.showAssistantAvatar,
                    showUserAvatar: settings.generalSetting.showUserAvatar,
                    systemPrompt: settings.generalSetting.systemPrompt,
                    enableArtifacts: value,
                    locale: settings.generalSetting.locale,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                context, l10n.themeSettings, CupertinoIcons.paintbrush),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  value: settings.generalSetting.theme,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  icon: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(50),
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatarCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                context, l10n.showAvatar, CupertinoIcons.person_crop_circle),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      l10n.showAssistantAvatar,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      l10n.showAssistantAvatarDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(60),
                      ),
                    ),
                    value: settings.generalSetting.showAssistantAvatar,
                    onChanged: (bool value) {
                      settings.updateGeneralSettings(
                        theme: settings.generalSetting.theme,
                        showAssistantAvatar: value,
                        showUserAvatar: settings.generalSetting.showUserAvatar,
                        systemPrompt: settings.generalSetting.systemPrompt,
                        enableArtifacts:
                            settings.generalSetting.enableArtifacts,
                        locale: settings.generalSetting.locale,
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context).colorScheme.outline.withAlpha(50),
                  ),
                  SwitchListTile(
                    title: Text(
                      l10n.showUserAvatar,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      l10n.showUserAvatarDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(60),
                      ),
                    ),
                    value: settings.generalSetting.showUserAvatar,
                    onChanged: (bool value) {
                      settings.updateGeneralSettings(
                        theme: settings.generalSetting.theme,
                        showAssistantAvatar:
                            settings.generalSetting.showAssistantAvatar,
                        showUserAvatar: value,
                        systemPrompt: settings.generalSetting.systemPrompt,
                        enableArtifacts:
                            settings.generalSetting.enableArtifacts,
                        locale: settings.generalSetting.locale,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSystemPromptCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                context, l10n.systemPrompt, CupertinoIcons.text_quote),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: settings.generalSetting.systemPrompt,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withAlpha(20),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withAlpha(20),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 5,
                      onChanged: (value) {
                        settings.updateGeneralSettings(
                          theme: settings.generalSetting.theme,
                          showAssistantAvatar:
                              settings.generalSetting.showAssistantAvatar,
                          showUserAvatar:
                              settings.generalSetting.showUserAvatar,
                          systemPrompt: value,
                          enableArtifacts:
                              settings.generalSetting.enableArtifacts,
                          locale: settings.generalSetting.locale,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.systemPromptDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(60),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
