import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatmcp/provider/settings_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatSetting extends StatelessWidget {
  const ChatSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    Text(l10n.modelSettings,
                        style: Theme.of(context).textTheme.titleLarge),
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
                  label: l10n
                      .temperature(modelSetting.temperature.toStringAsFixed(2)),
                  value: modelSetting.temperature,
                  min: 0.0,
                  max: 2.0,
                  onChanged: (value) => _updateModelSettings(
                    settingsProvider,
                    temperature: value,
                  ),
                  tooltip: l10n.temperatureTooltip,
                ),
                _buildSliderWithLabel(
                  context: context,
                  label: l10n.topP(modelSetting.topP.toStringAsFixed(2)),
                  value: modelSetting.topP,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) => _updateModelSettings(
                    settingsProvider,
                    topP: value,
                  ),
                  tooltip: l10n.topPTooltip,
                ),
                _buildNumberInput(
                  context: context,
                  label: l10n.maxTokens,
                  value: modelSetting.maxTokens,
                  onChanged: (value) => _updateModelSettings(
                    settingsProvider,
                    maxTokens: value,
                  ),
                  tooltip: l10n.maxTokensTooltip,
                ),
                _buildSliderWithLabel(
                  context: context,
                  label: l10n.frequencyPenalty(
                      modelSetting.frequencyPenalty.toStringAsFixed(2)),
                  value: modelSetting.frequencyPenalty,
                  min: -2.0,
                  max: 2.0,
                  onChanged: (value) => _updateModelSettings(
                    settingsProvider,
                    frequencyPenalty: value,
                  ),
                  tooltip: l10n.frequencyPenaltyTooltip,
                ),
                _buildSliderWithLabel(
                  context: context,
                  label: l10n.presencePenalty(
                      modelSetting.presencePenalty.toStringAsFixed(2)),
                  value: modelSetting.presencePenalty,
                  min: -2.0,
                  max: 2.0,
                  onChanged: (value) => _updateModelSettings(
                    settingsProvider,
                    presencePenalty: value,
                  ),
                  tooltip: l10n.presencePenaltyTooltip,
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
    final l10n = AppLocalizations.of(context)!;
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
          decoration: InputDecoration(
            hintText: l10n.enterMaxTokens,
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
