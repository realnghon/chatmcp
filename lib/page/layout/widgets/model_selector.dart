import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import 'package:ChatMcp/provider/chat_model_provider.dart';
import 'package:ChatMcp/llm/model.dart';
import 'package:ChatMcp/llm/llm_factory.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({super.key});

  bool _isModelSupported(String modelName) {
    return LLMFactoryHelper.modelMapping.keys
        .any((key) => modelName.startsWith(key));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatModelProvider>(
      builder: (context, chatModelProvider, child) {
        final availableModels = ProviderManager
            .chatModelProvider.availableModels
            .where((model) => _isModelSupported(model.name))
            .toList();

        return Container(
          constraints: const BoxConstraints(maxWidth: 250),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 8),
            position: PopupMenuPosition.under,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    availableModels
                        .firstWhere(
                          (model) =>
                              model.name == chatModelProvider.currentModel,
                          orElse: () => Model(name: '', label: '未知模型'),
                        )
                        .label,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more,
                    size: 18,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => availableModels
                .map(
                  (model) => PopupMenuItem<String>(
                    value: model.name,
                    child: Row(
                      children: [
                        if (model.name == chatModelProvider.currentModel)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        if (model.name == chatModelProvider.currentModel)
                          const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            model.label,
                            style: TextStyle(
                              color:
                                  model.name == chatModelProvider.currentModel
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onSelected: (String value) {
              if (_isModelSupported(value)) {
                ProviderManager.chatModelProvider.currentModel = value;
              }
            },
          ),
        );
      },
    );
  }
}
