import 'package:flutter/material.dart';
import 'package:ChatMcp/llm/model.dart' as llmModel;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:ChatMcp/llm/llm_factory.dart';

class ChatModelProvider extends ChangeNotifier {
  static final ChatModelProvider _instance = ChatModelProvider._internal();
  factory ChatModelProvider() => _instance;
  ChatModelProvider._internal() {
    _loadSavedModel();
  }

  bool _isInitialized = false;

  Future<void> loadAvailableModels() async {
    if (_isInitialized) return;

    final models = await LLMFactoryHelper.getAvailableModels();

    _availableModels.clear(); // 先清空列表
    _availableModels.addAll(models
        .map((model) => llmModel.Model(name: model, label: model))
        .toList());

    // 确保当前选择的模型在可用列表中
    if (!_availableModels.any((model) => model.name == _currentModel)) {
      _currentModel = _availableModels.first.name; // 如果不在，选择第一个可用的模型
      _saveSavedModel();
    }

    _isInitialized = true;
    notifyListeners();
  }

  final List<llmModel.Model> _availableModels = [];

  List<llmModel.Model> get availableModels => _availableModels;

  static const String _modelKey = 'current_model';
  String _currentModel = "gpt-4o-mini";

  String get currentModel => _currentModel;

  set currentModel(String model) {
    _currentModel = model;
    _saveSavedModel();
    notifyListeners();
  }

  Future<void> _loadSavedModel() async {
    final prefs = await SharedPreferences.getInstance();
    _currentModel = prefs.getString(_modelKey) ?? "gpt-4o-mini";
    Logger.root.info(
        'load model: ${prefs.getString(_modelKey)} currentModel: $_currentModel');
    notifyListeners();
  }

  Future<void> _saveSavedModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, _currentModel);
  }
}
