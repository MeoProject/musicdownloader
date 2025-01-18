import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:musicdownloader/state/settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    _loadDownloadPath();
  }

  Future<void> _loadDownloadPath() async {
    await Provider.of<Settings>(context, listen: false).loadDownloadPath();
  }

  Future<void> _selectDirectory() async {
    String? selectedPath = await FilePicker.platform.getDirectoryPath();
    Provider.of<Settings>(context, listen: false).downloadPath = selectedPath!;
    }

  @override
  Widget build(BuildContext context) {
    String downloadPath = Provider.of<Settings>(context).downloadPath;

    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('下载目录'),
            subtitle: Text(downloadPath.isEmpty ? '未设置' : downloadPath),
            leading: Icon(Icons.folder),
            onTap: _selectDirectory,
          ),
          ListTile(
            title: Text('关于'),
            leading: Icon(Icons.info),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '音乐下载器',
                applicationVersion: '1.0.1-beta.1',
                applicationIcon: Image.asset('assets/icon/app_icon.png',
                    width: 48, height: 48),
                children: [
                  Text('一个简单的音乐下载器'),
                  SizedBox(height: 8),
                  Text('© 2025 MeoProject 保留所有权利'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
