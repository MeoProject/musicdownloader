import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:musicdownloader/state/settings.dart';
import 'package:provider/provider.dart';
import '../i18n/quality_translations.dart';
import 'package:path/path.dart' as path;

final log = Logger();

class DownloadService {
  final Dio _dio = Dio();

  // 应用测试，暂时不使用正式后端
  // Future<String?> getDownloadUrl(
  //     String source, String songid, String quality) async {
  //   try {
  //     final response = await _dio.get(
  //         "https://ikun.laoguantx.top:19742/url/$source/$songid/$quality",
  //         options: Options(headers: {"X-Request-Key": "LXMusic_dmsowplaeq"}));
  //     if (response.statusCode != 200 || response.data['code'] != 0) {
  //       final errormsg = response.data['msg'];
  //       throw Exception('链接获取失败：$errormsg');
  //     }
  //     return response.data['data'].toString();
  //   } catch (e) {
  //     log.severe('链接获取失败, $source, $songid, $quality');
  //     return null;
  //   }
  // }

  Future<String?> getDownloadUrl(
      String source, String songid, String quality) async {
    try {
      final response = await _dio.get("https://lxmusic.ikunshare.com/url",
          queryParameters: {
            "source": source,
            "songId": songid,
            "quality": quality,
          },
          options: Options(headers: {"X-Request-Key": "110.42.57.14"}));
      if (response.statusCode != 200 || response.data['code'] != 0) {
        final errormsg = response.data['msg'];
        throw Exception('链接获取失败：$errormsg');
      }
      return response.data['data'].toString();
    } catch (e) {
      log.e('链接获取失败, $source, $songid, $quality', error: e);
      return null;
    }
  }

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
          '${song['artist']} - ${song['title']} - ${QualityTranslations.qualityNamesZh[quality]}.${_getFileExtension(quality)}'
              .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final savePath = path.join(downloadPath, fileName);

      if (!context.mounted) return null;
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (context) {
          bottomSheetContext = context;
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

      final url = await getDownloadUrl(source, songid, quality);
      if (url == null) {
        if (bottomSheetContext != null) {
          // ignore: use_build_context_synchronously
          Navigator.pop(bottomSheetContext!);
        }
        log.e('获取下载 URL 失败');
        Fluttertoast.showToast(msg: "获取下载 URL 失败");
        return null;
      }

      if (await Permission.storage.request().isGranted) {
        try {
          await _dio.download(
            url,
            savePath,
            options: Options(
              headers: {
                "User-Agent":
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 Edg/132.0.0.0"
              },
              responseType: ResponseType.stream,
            ),
            onReceiveProgress: (received, total) async {
              if (total != -1) {
                progressNotifier.value = received / total;
                if (received == total) {
                  try {
                    // final coverResponse = await Dio().get<Uint8List>(
                    //   song['img'],
                    //   options: Options(responseType: ResponseType.bytes),
                    // );
                    // final success = await _writeAudioTags(
                    //   path: savePath,
                    //   title: song['title'] ?? '未知标题',
                    //   artist: song['artist'] ?? '未知艺术家',
                    //   album: song['album'] ?? '未知专辑',
                    //   lyrics: song['lrc'] ?? '纯音乐或歌词获取失败',
                    //   artworkBytes: coverResponse.data,
                    //   artworkMime: 'image/jpeg',
                    // );
                    // if (success) {
                    //   log.i("标签写入成功");
                    // } else {
                    //   log.w("标签写入失败");
                    // }
                  } catch (e) {
                    log.e("标签写入异常", error: e);
                  }
                  navigator.pop();
                  Fluttertoast.showToast(msg: "下载完成：$fileName");
                }
              }
            },
          );
          return savePath;
        } catch (e) {
          if (bottomSheetContext != null) {
            // ignore: use_build_context_synchronously
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
        log.e('下载出错', error: e);
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
