import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String _currentEngine = 'tx';
  List<Map<String, dynamic>> _searchResults = [];

  String get currentEngine => _currentEngine;
  List<Map<String, dynamic>> get searchResults => _searchResults;

  void setCurrentEngine(String engine) {
    _currentEngine = engine;
    notifyListeners();
  }

  void setSearchResults(List<Map<String, dynamic>> results) {
    _searchResults = results;
    notifyListeners();
  }
}

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    Key? key,
    required AppState notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppStateProvider>()!
        .notifier!;
  }
}
