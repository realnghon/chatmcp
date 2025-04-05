import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';
import '../../provider/provider_manager.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KeysSettings extends StatefulWidget {
  const KeysSettings({super.key});

  @override
  State<KeysSettings> createState() => _KeysSettingsState();
}

class _KeysSettingsState extends State<KeysSettings> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Define LLM API configuration
  final Map<String, ApiConfig> _llmApiConfigs = {
    'openai': ApiConfig(
      title: 'OpenAI',
      iconPath: 'assets/logo/chatgpt.svg',
      accentColor: const Color(0xFF10A37F),
      requiresKey: true,
      requiresEndpoint: true,
    ),
    'claude': ApiConfig(
      title: 'Claude',
      iconPath: 'assets/logo/claude.svg',
      accentColor: const Color(0xFF7C3AED),
      requiresKey: true,
      requiresEndpoint: true,
    ),
    'deepseek': ApiConfig(
      title: 'DeepSeek',
      iconPath: 'assets/logo/deepseek.svg',
      accentColor: const Color(0xFF1A73E8),
      requiresKey: true,
      requiresEndpoint: true,
    ),
    'ollama': ApiConfig(
      title: 'Ollama',
      iconPath: 'assets/logo/ollama.svg',
      accentColor: const Color(0xFF1A73E8),
      requiresKey: false,
      requiresEndpoint: true,
    ),
  };

  // Use Map to manage controllers uniformly
  final Map<String, ApiControllers> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSettings();
  }

  void _initializeControllers() {
    // Initialize LLM API controllers
    for (var entry in _llmApiConfigs.entries) {
      _controllers[entry.key] = ApiControllers(
        keyController: entry.value.requiresKey ? TextEditingController() : null,
        endpointController:
            entry.value.requiresEndpoint ? TextEditingController() : null,
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.loadSettings();

    for (var entry in _llmApiConfigs.entries) {
      final apiSettings = settings.apiSettings[entry.key];
      if (apiSettings != null) {
        final controller = _controllers[entry.key]!;
        if (controller.keyController != null) {
          controller.keyController!.text = apiSettings.apiKey;
        }
        if (controller.endpointController != null) {
          controller.endpointController!.text = apiSettings.apiEndpoint;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      _buildSectionTitle(
                          context, l10n.llmKey, CupertinoIcons.cube_box),
                      ..._buildLlmApiSections(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CupertinoActivityIndicator()
                          : Text(
                              l10n.saveSettings,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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

  List<Widget> _buildLlmApiSections() {
    return _llmApiConfigs.entries
        .map((entry) => ApiSection(
              title: entry.value.title,
              iconPath: entry.value.iconPath,
              keyController: _controllers[entry.key]?.keyController,
              endpointController: _controllers[entry.key]?.endpointController,
              accentColor: entry.value.accentColor,
            ))
        .toList();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final settings = ProviderManager.settingsProvider;
        final Map<String, KeysSetting> apiSettings = {};

        // Save LLM API settings
        for (var entry in _llmApiConfigs.entries) {
          final controller = _controllers[entry.key]!;
          apiSettings[entry.key] = KeysSetting(
            apiKey: controller.keyController?.text ?? '',
            apiEndpoint: controller.endpointController?.text ?? '',
          );
        }

        await settings.updateApiSettings(apiSettings: apiSettings);
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
  final TextEditingController? endpointController;
  final Color accentColor;

  const ApiSection({
    super.key,
    required this.title,
    required this.iconPath,
    this.keyController,
    this.endpointController,
    required this.accentColor,
  });

  @override
  State<ApiSection> createState() => _ApiSectionState();
}

class _ApiSectionState extends State<ApiSection> {
  bool _isKeyVisible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.iconPath.isNotEmpty) ...[
                  SvgPicture.asset(
                    widget.iconPath,
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (widget.keyController != null) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.keyController,
                obscureText: !_isKeyVisible,
                decoration: InputDecoration(
                  labelText: l10n.apiKey,
                  hintText: l10n.enterApiKey(widget.title),
                  labelStyle: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(102),
                  ),
                  hintStyle: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(102),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color:
                          Theme.of(context).colorScheme.outline.withAlpha(51),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color:
                          Theme.of(context).colorScheme.outline.withAlpha(51),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.lock,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isKeyVisible
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () =>
                        setState(() => _isKeyVisible = !_isKeyVisible),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 10) {
                    return l10n.apiKeyValidation;
                  }
                  return null;
                },
              ),
            ],
            if (widget.endpointController != null) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.endpointController,
                decoration: InputDecoration(
                  labelText: l10n.apiEndpoint,
                  hintText: l10n.enterApiEndpoint,
                  labelStyle: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(102),
                  ),
                  hintStyle: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(102),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.link,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// New helper class
class ApiConfig {
  final String title;
  final String iconPath;
  final Color accentColor;
  final bool requiresKey;
  final bool requiresEndpoint;

  ApiConfig({
    required this.title,
    required this.iconPath,
    this.accentColor = const Color(0xFF1A73E8),
    this.requiresKey = true,
    this.requiresEndpoint = true,
  });
}

class ApiControllers {
  final TextEditingController? keyController;
  final TextEditingController? endpointController;

  ApiControllers({this.keyController, this.endpointController});

  void dispose() {
    keyController?.dispose();
    endpointController?.dispose();
  }
}
