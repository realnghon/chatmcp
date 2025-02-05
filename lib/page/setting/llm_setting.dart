import 'package:ChatMcp/utils/platform.dart';
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
  final _deepseekApiKeyController = TextEditingController();
  final _deepseekApiEndpointController = TextEditingController();
  final _ollamaApiEndpointController = TextEditingController();
  bool _isLoading = false;

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
    _deepseekApiKeyController.dispose();
    _deepseekApiEndpointController.dispose();
    _ollamaApiEndpointController.dispose();
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

    final deepseekSettings = settings.apiSettings['deepseek'];
    if (deepseekSettings != null) {
      _deepseekApiKeyController.text = deepseekSettings.apiKey;
      _deepseekApiEndpointController.text = deepseekSettings.apiEndpoint;
    }

    final ollamaSettings = settings.apiSettings['ollama'];
    if (ollamaSettings != null) {
      _ollamaApiEndpointController.text = ollamaSettings.apiEndpoint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.8),
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
                      ApiSection(
                        title: 'OpenAI',
                        iconPath: 'assets/openai_icon.png',
                        keyController: _openaiApiKeyController,
                        endpointController: _openaiApiEndpointController,
                        accentColor: const Color(0xFF10A37F),
                      ),
                      ApiSection(
                        title: 'Claude',
                        iconPath: 'assets/claude_icon.png',
                        keyController: _claudeApiKeyController,
                        endpointController: _claudeApiEndpointController,
                        accentColor: const Color(0xFF7C3AED),
                      ),
                      ApiSection(
                        title: 'DeepSeek',
                        iconPath: 'assets/deepseek_icon.png',
                        keyController: _deepseekApiKeyController,
                        endpointController: _deepseekApiEndpointController,
                        accentColor: const Color(0xFF2563EB),
                      ),
                      ApiSection(
                        title: 'Ollama',
                        iconPath: 'assets/ollama_icon.png',
                        endpointController: _ollamaApiEndpointController,
                        accentColor: const Color(0xFF000000),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final settings = ProviderManager.settingsProvider;

        final openaiSetting = ApiSetting(
          apiKey: _openaiApiKeyController.text,
          apiEndpoint: _openaiApiEndpointController.text,
        );

        final claudeSetting = ApiSetting(
          apiKey: _claudeApiKeyController.text,
          apiEndpoint: _claudeApiEndpointController.text,
        );

        final deepseekSetting = ApiSetting(
          apiKey: _deepseekApiKeyController.text,
          apiEndpoint: _deepseekApiEndpointController.text,
        );

        final ollamaSetting = ApiSetting(
          apiKey: "",
          apiEndpoint: _ollamaApiEndpointController.text,
        );

        await settings.updateApiSettings(apiSettings: {
          'openai': openaiSetting,
          'claude': claudeSetting,
          'deepseek': deepseekSetting,
          'ollama': ollamaSetting,
        });

        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
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
                backgroundColor: Colors.green,
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

class ApiSection extends StatefulWidget {
  final String title;
  final String iconPath;
  final TextEditingController? keyController;
  final TextEditingController endpointController;
  final Color accentColor;

  const ApiSection({
    super.key,
    required this.title,
    required this.iconPath,
    this.keyController,
    required this.endpointController,
    required this.accentColor,
  });

  @override
  State<ApiSection> createState() => _ApiSectionState();
}

class _ApiSectionState extends State<ApiSection> {
  bool _isKeyVisible = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withAlpha(51)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.api, color: widget.accentColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
              ],
            ),
            if (widget.keyController != null) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.keyController,
                obscureText: !_isKeyVisible,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your ${widget.title} API Key',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.key, color: widget.accentColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isKeyVisible ? Icons.visibility_off : Icons.visibility,
                      color: widget.accentColor,
                    ),
                    onPressed: () =>
                        setState(() => _isKeyVisible = !_isKeyVisible),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: widget.accentColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 10) {
                    return 'API Key must be at least 10 characters';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.endpointController,
              decoration: InputDecoration(
                labelText: 'API Endpoint',
                hintText: 'Enter API endpoint URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.link, color: widget.accentColor),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.accentColor, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
