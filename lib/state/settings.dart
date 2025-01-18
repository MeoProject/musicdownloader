import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class Settings with ChangeNotifier {
  String _downloadPath = '';

  String get downloadPath => _downloadPath;

  set downloadPath(String path) {
    _downloadPath = path;
    _saveDownloadPath(path);
    notifyListeners();
  }

  Future<void> loadDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    _downloadPath = prefs.getString('downloadPath') ?? '/storage/emulated/0/Download';
    if (_downloadPath.isEmpty) {
      final directory = await Directory('/storage/emulated/0/Download').exists();
      if (directory) {
        _downloadPath = '/storage/emulated/0/Download';
      }
    }
    notifyListeners();
  }

  Future<void> _saveDownloadPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('downloadPath', path);
  }
}
