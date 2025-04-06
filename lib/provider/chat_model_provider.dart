import 'package:flutter/material.dart';
import 'package:chatmcp/llm/model.dart' as llm_model;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmcp/llm/llm_factory.dart';
import 'dart:convert';
import 'package:logging/logging.dart';

class ChatModelProvider extends ChangeNotifier {
  static final ChatModelProvider _instance = ChatModelProvider._internal();
  factory ChatModelProvider() => _instance;
  ChatModelProvider._internal() {
    _loadSavedModel();
  }

  Future<void> loadAvailableModels() async {
    final models = await LLMFactoryHelper.getAvailableModels();
    Logger.root.info('Available models loaded: $models');

    _availableModels.clear(); // Clear the list first
    _availableModels.addAll(models.toList());

    // Ensure the current model is in the available list and the list is not empty
    if (_availableModels.isEmpty) {
      notifyListeners();
      return;
    }

    if (!_availableModels.any((model) => model.name == _currentModel.name)) {
      _currentModel = _availableModels.first;
      _saveSavedModel();
    }

    notifyListeners();
  }

  final List<llm_model.Model> _availableModels = [];

  List<llm_model.Model> get availableModels => _availableModels;

  List<llm_model.Model> getModels() {
    return _availableModels;
  }

  // Get the currently selected model
  static const String _modelKey = 'current_model';
  llm_model.Model _currentModel = llm_model.Model(
      name: "gpt-4o-mini", label: "GPT-4o-mini", provider: "openai");

  llm_model.Model get currentModel => _currentModel;

  set currentModel(llm_model.Model model) {
    _currentModel = model;
    _saveSavedModel();
    notifyListeners();
  }

  Future<void> _loadSavedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final modelName = prefs.getString(_modelKey) ?? "";
    if (modelName.isNotEmpty) {
      _currentModel = llm_model.Model.fromJson(jsonDecode(modelName));
    }
    notifyListeners();
  }

  Future<void> _saveSavedModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, _currentModel.toString());
  }
}
