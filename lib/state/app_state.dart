import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class AppState extends ChangeNotifier {
  String _currentEngine = 'tx';
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _searchHistory = [];
  String _currentSearchQuery = '';
  String _configFilePath = '';

  String get currentEngine => _currentEngine;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  List<String> get searchHistory => _searchHistory;
  String get currentSearchQuery => _currentSearchQuery;

  AppState() {
    _loadConfig();
  }

  void setCurrentEngine(String engine) {
    _currentEngine = engine;
    notifyListeners();
  }

  void setSearchResults(List<Map<String, dynamic>> results) {
    _searchResults = results;
    notifyListeners();
  }

  void addSearchHistory(String query) {
    _searchHistory.add(query);
    _saveConfig();
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }

  void setCurrentSearchQuery(String query) {
    _currentSearchQuery = query;
    _saveConfig();
    notifyListeners();
  }

  Future<void> _loadConfig() async {
    final directory = await getApplicationDocumentsDirectory();
    _configFilePath = '${directory.path}/config.json';
    final file = File(_configFilePath);
    if (await file.exists()) {
      final contents = await file.readAsString();
      final json = jsonDecode(contents);
      _searchHistory = List<String>.from(json['searchHistory'] ?? []);
      _currentSearchQuery = json['currentSearchQuery'] ?? '';
    }
  }

  Future<void> _saveConfig() async {
    final file = File(_configFilePath);
    final json = jsonEncode({
      'searchHistory': _searchHistory,
      'currentSearchQuery': _currentSearchQuery,
    });
    await file.writeAsString(json);
  }
}

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppStateProvider>()!
        .notifier!;
  }
}
