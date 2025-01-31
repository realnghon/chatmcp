import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';
import '../../provider/provider_manager.dart';

class LlmSettings extends StatefulWidget {
  const LlmSettings({super.key});

  @override
  State<LlmSettings> createState() => _LlmSettingsState();
}

class _LlmSettingsState extends State<LlmSettings> {
  final _formKey = GlobalKey<FormState>();
  final _openaiApiKeyController = TextEditingController();
  final _openaiApiEndpointController = TextEditingController();
  final _claudeApiKeyController = TextEditingController();
  final _claudeApiEndpointController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _openaiApiKeyController.dispose();
    _openaiApiEndpointController.dispose();
    _claudeApiKeyController.dispose();
    _claudeApiEndpointController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.loadSettings();

    final openaiSettings = settings.apiSettings['openai'];
    if (openaiSettings != null) {
      _openaiApiKeyController.text = openaiSettings.apiKey;
      _openaiApiEndpointController.text = openaiSettings.apiEndpoint;
    }

    final claudeSettings = settings.apiSettings['claude'];
    if (claudeSettings != null) {
      _claudeApiKeyController.text = claudeSettings.apiKey;
      _claudeApiEndpointController.text = claudeSettings.apiEndpoint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text(
              'OpenAI API',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _openaiApiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Please enter your OpenAI API Key',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 10) {
                  return 'API Key must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _openaiApiEndpointController,
              decoration: const InputDecoration(
                labelText: 'API Endpoint',
                hintText: 'https://api.openai.com/v1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Claude API',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _claudeApiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Please enter your Claude API Key',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 10) {
                  return 'API Key must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _claudeApiEndpointController,
              decoration: const InputDecoration(
                labelText: 'API Endpoint',
                hintText: 'https://api.anthropic.com/v1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Save Settings'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final settings = ProviderManager.settingsProvider;

      final openaiSetting = ApiSetting(
        apiKey: _openaiApiKeyController.text,
        apiEndpoint: _openaiApiEndpointController.text,
      );

      final claudeSetting = ApiSetting(
        apiKey: _claudeApiKeyController.text,
        apiEndpoint: _claudeApiEndpointController.text,
      );

      await settings.updateSettings(
        apiSettings: {
          'openai': openaiSetting,
          'claude': claudeSetting,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    }
  }
}
