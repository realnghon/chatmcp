import 'package:flutter/material.dart';
import 'package:ChatMcp/llm/model.dart' as llmModel;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ChatMcp/llm/llm_factory.dart';
import 'dart:convert';

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
    _availableModels.addAll(models.toList());

    // 确保当前选择的模型在可用列表中，并且列表不为空
    if (_availableModels.isEmpty) {
      // 如果没有可用模型，保持使用默认模型
      _isInitialized = true;
      notifyListeners();
      return;
    }

    if (!_availableModels.any((model) => model.name == _currentModel.name)) {
      _currentModel = _availableModels.first;
      _saveSavedModel();
    }

    _isInitialized = true;
    notifyListeners();
  }

  final List<llmModel.Model> _availableModels = [];

  List<llmModel.Model> get availableModels => _availableModels;

  List<llmModel.Model> getModels() {
    return _availableModels;
  }

  // 获取当前选中的模型
  static const String _modelKey = 'current_model';
  llmModel.Model _currentModel = llmModel.Model(
      name: "gpt-4o-mini", label: "GPT-4o-mini", provider: "openai");

  llmModel.Model get currentModel => _currentModel;

  set currentModel(llmModel.Model model) {
    _currentModel = model;
    _saveSavedModel();
    notifyListeners();
  }

  Future<void> _loadSavedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final modelName = prefs.getString(_modelKey) ?? "";
    if (modelName.isNotEmpty) {
      _currentModel = llmModel.Model.fromJson(jsonDecode(modelName));
    }
    notifyListeners();
  }

  Future<void> _saveSavedModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, _currentModel.toString());
  }
}
