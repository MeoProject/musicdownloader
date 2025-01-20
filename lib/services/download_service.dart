import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:musicdownloader/state/settings.dart';
import 'package:provider/provider.dart';
import 'search_service.dart';
import 'package:path/path.dart' as path;

final log = Logger("DownloadService");

class DownloadService {
  final SearchService _searchService = SearchService();
  final Dio _dio = Dio();

  Future<String?> downloadMusic(String source, String songid, String quality,
      Map<String, dynamic> song, BuildContext context) async {
    try {
      if (!context.mounted) return null;
      final settingsState = Provider.of<Settings>(context, listen: false);
      var downloadPath = settingsState.downloadPath;
      final navigator = Navigator.of(context);
      final progressNotifier = ValueNotifier<double>(0);
      BuildContext? bottomSheetContext;

      if (downloadPath.isEmpty) {
        await settingsState.loadDownloadPath();
        downloadPath = settingsState.downloadPath;
        if (downloadPath.isEmpty) {
          throw Exception('请先设置下载目录');
        }
      }

      final fileName =
          '${song['artist']} - ${song['title']} - $quality.${_getFileExtension(quality)}'
              .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final savePath = path.join(downloadPath, fileName);

      if (!context.mounted) return null;
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (context) {
          bottomSheetContext = context; // 保存context引用
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${song['artist']} - ${song['title']} - $quality",
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('隐藏'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<double>(
                    valueListenable: progressNotifier,
                    builder: (context, progress, _) {
                      return Column(
                        children: [
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 8),
                          Text('${(progress * 100).toStringAsFixed(1)}%'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );

      final url = await _searchService.getDownloadUrl(source, songid, quality);
      if (url == null) {
        if (bottomSheetContext != null) {
          Navigator.pop(bottomSheetContext!);
        }
        log.severe('获取下载 URL 失败');
        Fluttertoast.showToast(msg: "获取下载 URL 失败");
        return null;
      }

      if (await Permission.storage.request().isGranted) {
        try {
          await _dio.download(
            url,
            savePath,
            options: Options(
              headers: {"User-Agent": "okhttp/1.0.0"},
              responseType: ResponseType.stream,
            ),
            onReceiveProgress: (received, total) {
              if (total != -1) {
                progressNotifier.value = received / total;
                if (received == total) {
                  navigator.pop();
                  Fluttertoast.showToast(msg: "下载完成：$fileName");
                }
              }
            },
          );
          return savePath;
        } catch (e) {
          if (bottomSheetContext != null) {
            Navigator.pop(bottomSheetContext!);
          }
          navigator.pop();
          rethrow;
        } finally {
          progressNotifier.dispose();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        Fluttertoast.showToast(msg: "下载出错：$e");
        log.severe('下载出错: $e');
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
