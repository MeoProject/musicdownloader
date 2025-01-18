import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:musicdownloader/state/settings.dart';
import 'package:provider/provider.dart';
import 'search_service.dart';

class DownloadService {
  final SearchService _searchService = SearchService();
  final Dio _dio = Dio();

  Future<String?> downloadMusic(String source, String songmid, String quality,
      Map<String, dynamic> song, BuildContext context) async {

    try {
      final settingsState = Provider.of<Settings>(context, listen: false);
      final downloadPath = settingsState.downloadPath;

      final url = await _searchService.getDownloadUrl(source, songmid, quality);
      if (url == null) {
        if (kDebugMode) {
          print('获取下载 URL 失败');
        }
        return null;
      }

      if (await Permission.storage.request().isGranted) {
        final extension = _getFileExtension(quality);
        final filename = '${song['title']} - ${song['artist']}.$extension';
        final filePath = '$downloadPath/$filename';

        final taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: downloadPath,
          fileName: filename,
          showNotification: true,
          saveInPublicStorage: true,
          openFileFromNotification: true,
        );

        FlutterDownloader.registerCallback((id, status, progress) async {
          if (taskId == id) {
            if (kDebugMode) {
              print('下载进度: $progress%');
              print('下载状态: $status');
            }
          }
          if (status == DownloadTaskStatus.complete.index) {
            final coverUrl = song['img'];
            final coverDir = await getTemporaryDirectory();
            final coverPath = '${coverDir.path}/cover.jpg';
            await _dio.download(coverUrl, coverPath);
            if (kDebugMode) {
              print('下载完成');
            }
          }
        });

        return filePath;
      }
    } catch (e) {
      if (kDebugMode) {
        print('下载出错: $e');
      }
      return null;
    }
    return null;
  }

  String _getFileExtension(String quality) {
    switch (quality) {
      case 'flac':
      case 'flac24bit':
      case 'sky':
      case 'dolby':
      case 'effect':
      case 'effect_plus':
      case 'master':
        return 'flac';
      case '128k':
      case '320k':
        return 'mp3';
      default:
        return 'mp3';
    }
  }
}
