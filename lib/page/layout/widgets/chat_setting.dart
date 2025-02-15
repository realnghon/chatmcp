import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ChatMcp/provider/settings_provider.dart';

class ChatSetting extends StatelessWidget {
  const ChatSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final modelSetting = settingsProvider.modelSetting;

        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('模型设置', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _resetModelSettings(settingsProvider),
                      icon: const Icon(Icons.reset_tv),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSliderWithLabel(
                  context: context,
                  label:
                      'Temperature: ${modelSetting.temperature.toStringAsFixed(2)}',
                  value: modelSetting.temperature,
                  min: 0.0,
                  max: 2.0,
                  onChanged: (value) => _updateModelSettings(
                    settingsProvider,
                    temperature: value,
                  ),
                  tooltip: '''采样温度控制输出的随机性：
• 0.0：适合代码生成和数学解题
• 1.0：适合数据抽取和分析
• 1.3：适合通用对话和翻译
• 1.5：适合创意写作和诗歌创作''',
                ),
                _buildSliderWithLabel(
                  context: context,
                  label: 'Top P: ${modelSetting.topP.toStringAsFixed(2)}',
                  value: modelSetting.topP,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) => _updateModelSettings(
                    settingsProvider,
                    topP: value,
                  ),
                  tooltip:
                      'Top P（核采样）是temperature的替代方案。模型只考虑累积概率超过P的标记。建议不要同时修改temperature和top_p。',
                ),
                _buildNumberInput(
                  context: context,
                  label: 'Max Tokens',
                  value: modelSetting.maxTokens,
                  onChanged: (value) => _updateModelSettings(
                    settingsProvider,
                    maxTokens: value,
                  ),
                  tooltip: '生成的最大令牌数。一个令牌大约等于4个字符。较长的对话需要更多的令牌。',
                ),
                _buildSliderWithLabel(
                  context: context,
                  label:
                      'Frequency Penalty: ${modelSetting.frequencyPenalty.toStringAsFixed(2)}',
                  value: modelSetting.frequencyPenalty,
                  min: -2.0,
                  max: 2.0,
                  onChanged: (value) => _updateModelSettings(
                    settingsProvider,
                    frequencyPenalty: value,
                  ),
                  tooltip: '频率惩罚参数。正值会根据新标记在文本中的现有频率来惩罚它们，降低模型逐字重复同样内容的可能性。',
                ),
                _buildSliderWithLabel(
                  context: context,
                  label:
                      'Presence Penalty: ${modelSetting.presencePenalty.toStringAsFixed(2)}',
                  value: modelSetting.presencePenalty,
                  min: -2.0,
                  max: 2.0,
                  onChanged: (value) => _updateModelSettings(
                    settingsProvider,
                    presencePenalty: value,
                  ),
                  tooltip: '存在惩罚参数。正值会根据新标记是否出现在文本中来惩罚它们，增加模型谈论新主题的可能性。',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliderWithLabel({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    String? tooltip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        if (tooltip != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tooltip,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNumberInput({
    required BuildContext context,
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
    String? tooltip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        if (tooltip != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tooltip,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
        TextField(
          controller: TextEditingController(text: value?.toString() ?? ''),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '输入最大令牌数',
          ),
          onChanged: (value) {
            if (value.isEmpty) {
              onChanged(null);
            } else {
              onChanged(int.tryParse(value));
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _updateModelSettings(
    SettingsProvider provider, {
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
  }) {
    final currentSettings = provider.modelSetting;
    provider.updateModelSettings(
      temperature: temperature ?? currentSettings.temperature,
      maxTokens: maxTokens,
      topP: topP ?? currentSettings.topP,
      frequencyPenalty: frequencyPenalty ?? currentSettings.frequencyPenalty,
      presencePenalty: presencePenalty ?? currentSettings.presencePenalty,
    );
  }

  Future<void> _resetModelSettings(SettingsProvider provider) async {
    await provider.resetModelSettings();
  }
}
