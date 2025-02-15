import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';
import 'package:ChatMcp/utils/color.dart';

class GeneralSettings extends StatefulWidget {
  const GeneralSettings({super.key});

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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
                      // 头像显示设置卡片
                      _buildAvatarCard(context),
                      // System Prompt 设置卡片
                      _buildSystemPromptCard(context),
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

  Widget _buildThemeCard(BuildContext context) {
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
                const Row(
                  children: [
                    Icon(Icons.palette, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Theme Settings',
                      style: TextStyle(
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
                    labelText: 'Theme',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.color_lens),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'light',
                      child: Text('Light Theme'),
                    ),
                    DropdownMenuItem(
                      value: 'dark',
                      child: Text('Dark Theme'),
                    ),
                    DropdownMenuItem(
                      value: 'system',
                      child: Text('Follow System'),
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
                const Row(
                  children: [
                    Icon(Icons.face, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Show Avatar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Show Assistant Avatar'),
                  subtitle: const Text(
                      'Show the avatar of the AI assistant in the conversation'),
                  value: settings.generalSetting.showAssistantAvatar,
                  onChanged: (bool value) {
                    settings.updateGeneralSettings(
                      theme: settings.generalSetting.theme,
                      showAssistantAvatar: value,
                      showUserAvatar: settings.generalSetting.showUserAvatar,
                      systemPrompt: settings.generalSetting.systemPrompt,
                    );
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Show User Avatar'),
                  subtitle: const Text(
                      'Show the avatar of the user in the conversation'),
                  value: settings.generalSetting.showUserAvatar,
                  onChanged: (bool value) {
                    settings.updateGeneralSettings(
                      theme: settings.generalSetting.theme,
                      showAssistantAvatar:
                          settings.generalSetting.showAssistantAvatar,
                      showUserAvatar: value,
                      systemPrompt: settings.generalSetting.systemPrompt,
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
                const Row(
                  children: [
                    Icon(Icons.psychology, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'System Prompt',
                      style: TextStyle(
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
                    labelText: 'System Prompt',
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
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note: This is the system prompt for the conversation with the AI assistant, used to set the behavior and style of the assistant.',
                  style: TextStyle(
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

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 由于设置是实时保存的，这里只需要显示保存成功的提示
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.white),
                    SizedBox(width: 8),
                    Text('Settings saved successfully'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: AppColors.green,
              ),
            );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
