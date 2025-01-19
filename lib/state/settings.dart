import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class Settings with ChangeNotifier {
  String _downloadPath = '';
  String _configFilePath = '';

  String get downloadPath => _downloadPath;

  set downloadPath(String path) {
    _downloadPath = path;
    _saveConfig();
    notifyListeners();
  }

  Future<void> loadDownloadPath() async {
    await _loadConfig();
    notifyListeners();
  }

  Future<void> _loadConfig() async {
    final directory = await getApplicationDocumentsDirectory();
    _configFilePath = '${directory.path}/config.json';
    final file = File(_configFilePath);
    if (await file.exists()) {
      final contents = await file.readAsString();
      final json = jsonDecode(contents);
      _downloadPath = json['downloadPath'] ?? '/storage/emulated/0/Download';
    } else {
      _downloadPath = '/storage/emulated/0/Download';
      await _saveConfig();
    }
  }

  Future<void> _saveConfig() async {
    final file = File(_configFilePath);
    final json = jsonEncode({'downloadPath': _downloadPath});
    await file.writeAsString(json);
  }
}
