import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';
import '../../provider/provider_manager.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class KeysSettings extends StatefulWidget {
  const KeysSettings({super.key});

  @override
  State<KeysSettings> createState() => _KeysSettingsState();
}

class _KeysSettingsState extends State<KeysSettings> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // 定义LLM API配置
  final Map<String, ApiConfig> _llmApiConfigs = {
    'openai': ApiConfig(
      title: 'OpenAI',
      iconPath: 'assets/openai_icon.png',
      accentColor: const Color(0xFF10A37F),
      requiresKey: true,
      requiresEndpoint: true,
    ),
    'claude': ApiConfig(
      title: 'Claude',
      iconPath: 'assets/claude_icon.png',
      accentColor: const Color(0xFF7C3AED),
      requiresKey: true,
      requiresEndpoint: true,
    ),
    'deepseek': ApiConfig(
      title: 'DeepSeek',
      iconPath: 'assets/deepseek_icon.png',
      accentColor: const Color(0xFF1A73E8),
      requiresKey: true,
      requiresEndpoint: true,
    ),
    'ollama': ApiConfig(
      title: 'Ollama',
      iconPath: 'assets/ollama_icon.png',
      accentColor: const Color(0xFF1A73E8),
      requiresKey: false,
      requiresEndpoint: true,
    ),
  };

  // 定义Tools API配置
  final Map<String, ApiConfig> _toolsApiConfigs = {
    'tavily': ApiConfig(
      title: 'Tavily Search',
      iconPath: 'assets/tavily_icon.png',
      accentColor: const Color(0xFF6366F1),
      requiresKey: true,
      requiresEndpoint: false,
    ),
  };

  // 使用Map统一管理控制器
  final Map<String, ApiControllers> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSettings();
  }

  void _initializeControllers() {
    // 初始化 LLM API 控制器
    for (var entry in _llmApiConfigs.entries) {
      _controllers[entry.key] = ApiControllers(
        keyController: entry.value.requiresKey ? TextEditingController() : null,
        endpointController:
            entry.value.requiresEndpoint ? TextEditingController() : null,
      );
    }
    // 初始化 Tools API 控制器
    for (var entry in _toolsApiConfigs.entries) {
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

    for (var entry in _toolsApiConfigs.entries) {
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
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
                      Text(l10n.llmKey,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      ..._buildLlmApiSections(),
                      const SizedBox(height: 12),
                      Text(l10n.toolKey,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      ..._buildToolsApiSections(),
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
                      foregroundColor: AppColors.white,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white),
                            ),
                          )
                        : Text(
                            l10n.saveSettings,
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

  List<Widget> _buildToolsApiSections() {
    return _toolsApiConfigs.entries
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

        // 保存 LLM API 设置
        for (var entry in _llmApiConfigs.entries) {
          final controller = _controllers[entry.key]!;
          apiSettings[entry.key] = KeysSetting(
            apiKey: controller.keyController?.text ?? '',
            apiEndpoint: controller.endpointController?.text ?? '',
          );
        }

        // 保存 Tools API 设置
        for (var entry in _toolsApiConfigs.entries) {
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
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey.withAlpha(51)),
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
                  labelText: l10n.apiKey,
                  hintText: l10n.enterApiKey(widget.title),
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
                    return l10n.apiKeyValidation;
                  }
                  return null;
                },
              ),
            ],
            if (widget.endpointController != null) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.endpointController,
                decoration: InputDecoration(
                  labelText: l10n.apiEndpoint,
                  hintText: l10n.enterApiEndpoint,
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
          ],
        ),
      ),
    );
  }
}

// 新增的辅助类
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
