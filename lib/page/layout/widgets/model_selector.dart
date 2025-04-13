import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatmcp/provider/provider_manager.dart';
import 'package:chatmcp/provider/chat_model_provider.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:chatmcp/llm/llm_factory.dart';
import 'package:flutter_popup/flutter_popup.dart';

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

        return ModelSelectorPopup(
          availableModels: availableModels,
          isCurrentModel: isCurrentModel,
          onModelSelected: (model) {
            ProviderManager.chatModelProvider.currentModel = model;
          },
        );
      },
    );
  }
}

class ModelSelectorPopup extends StatefulWidget {
  final List<Model> availableModels;
  final bool Function(Model) isCurrentModel;
  final void Function(Model) onModelSelected;

  const ModelSelectorPopup({
    super.key,
    required this.availableModels,
    required this.isCurrentModel,
    required this.onModelSelected,
  });

  @override
  State<ModelSelectorPopup> createState() => _ModelSelectorPopupState();
}

class _ModelSelectorPopupState extends State<ModelSelectorPopup> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 按 provider 对模型进行分组并根据搜索文本过滤
  Map<String, List<Model>> _getFilteredModelsByProvider() {
    final modelsByProvider = <String, List<Model>>{};

    // 筛选匹配搜索文本的模型
    final filteredModels = widget.availableModels.where((model) {
      return _searchText.isEmpty ||
          model.label.toLowerCase().contains(_searchText) ||
          model.provider.toLowerCase().contains(_searchText);
    }).toList();

    for (var model in filteredModels) {
      modelsByProvider.putIfAbsent(model.provider, () => []).add(model);
    }

    return modelsByProvider;
  }

  // 构建模型列表
  Widget _buildModelList() {
    final modelsByProvider = _getFilteredModelsByProvider();

    if (modelsByProvider.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No results found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final List<Widget> items = [];

    modelsByProvider.forEach((provider, models) {
      // 添加分隔线
      if (items.isNotEmpty) {
        items.add(const Divider(height: 1, indent: 8, endIndent: 8));
      }

      // 添加提供商标题
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
          child: Text(
            provider,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );

      // 添加该提供商下的所有模型
      for (var model in models) {
        items.add(
          InkWell(
            onTap: () {
              widget.onModelSelected(model);
              // 清除搜索框内容
              _searchController.clear();
              _searchText = '';
              // 关闭弹窗
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      model.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.isCurrentModel(model)
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                    ),
                  ),
                  if (widget.isCurrentModel(model))
                    Icon(
                      Icons.check,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }
    });

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentModel = widget.availableModels.firstWhere(
      (model) => widget.isCurrentModel(model),
      orElse: () => Model(name: '', label: 'Loading...', provider: ''),
    );

    return CustomPopup(
      showArrow: true,
      arrowColor: Theme.of(context).popupMenuTheme.color ?? Colors.white,
      backgroundColor: Theme.of(context).popupMenuTheme.color ?? Colors.white,
      barrierColor: Colors.transparent,
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter popupSetState) {
          return Container(
            constraints: BoxConstraints(
              maxWidth: 280,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 搜索框
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
                  child: TextField(
                    controller: _searchController,
                    style: Theme.of(context).textTheme.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: Theme.of(context).textTheme.bodySmall,
                      prefixIcon: const Icon(Icons.search, size: 16),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withAlpha(128),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                    ),
                    onChanged: (value) {
                      popupSetState(() {
                        _searchText = value.toLowerCase();
                      });
                    },
                  ),
                ),
                // 模型列表
                Flexible(
                  child: _buildModelList(),
                ),
              ],
            ),
          );
        },
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                currentModel.label,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
    );
  }
}
