import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatmcp/provider/provider_manager.dart';
import 'package:chatmcp/provider/chat_model_provider.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:chatmcp/llm/llm_factory.dart';
import 'package:chatmcp/generated/app_localizations.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({super.key});

  bool isCurrentModel(Model model) {
    return model.name == ProviderManager.chatModelProvider.currentModel.name &&
        model.provider ==
            ProviderManager.chatModelProvider.currentModel.provider;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatModelProvider>(
      builder: (context, chatModelProvider, child) {
        final availableModels = ProviderManager
            .chatModelProvider.availableModels
            .where((model) => LLMFactoryHelper.isChatModel(model))
            .toList();

        return Container(
          constraints: const BoxConstraints(maxWidth: 250),
          child: PopupMenuButton<String>(
            tooltip: AppLocalizations.of(context)?.selectModel,
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
                  Flexible(
                    child: Text(
                      availableModels
                          .firstWhere(
                            (model) => isCurrentModel(model),
                            orElse: () => Model(
                                name: '', label: 'Loading...', provider: ''),
                          )
                          .label,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
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
            itemBuilder: (context) {
              // 按 provider 对模型进行分组
              final modelsByProvider = <String, List<Model>>{};
              for (var model in availableModels) {
                modelsByProvider
                    .putIfAbsent(model.provider, () => [])
                    .add(model);
              }

              // 构建菜单项列表
              final menuItems = <PopupMenuEntry<String>>[];
              modelsByProvider.forEach((provider, models) {
                // 添加 provider 标题
                if (menuItems.isNotEmpty) {
                  menuItems.add(const PopupMenuDivider());
                }
                menuItems.add(
                  PopupMenuItem<String>(
                    enabled: false,
                    height: 16,
                    child: Text(
                      provider,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                );

                // 添加该 provider 下的所有模型
                for (var model in models) {
                  menuItems.add(
                    PopupMenuItem<String>(
                      value: "${model.provider}|${model.name}",
                      height: 32,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                model.label,
                                style: TextStyle(
                                  color: isCurrentModel(model)
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ),
                            if (isCurrentModel(model))
                              Icon(
                                Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              });

              return menuItems;
            },
            onSelected: (String value) {
              final selectedValue = value.split('|');
              final selectedModel = availableModels.firstWhere(
                (model) =>
                    model.name == selectedValue[1] &&
                    model.provider == selectedValue[0],
              );
              ProviderManager.chatModelProvider.currentModel = selectedModel;
            },
          ),
        );
      },
    );
  }
}
