import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../custom_transformer.dart';
import '../../utils/format_utils.dart';

final Dio http = Dio(BaseOptions(
  validateStatus: (status) => true,
))
  ..transformer = CustomTransformer();

Future<List<Map<String, dynamic>>> searchTX(String keyword, int limit,
    {int page = 1}) async {
  try {
    final response = await http.post(
      'https://u.y.qq.com/cgi-bin/musicu.fcg',
      data: {
        'comm': {
          'ct': 11,
          'cv': '1003006',
          'v': '1003006',
          'os_ver': '12',
          'phonetype': '0',
          'devicelevel': '31',
          'tmeAppID': 'qqmusiclight',
          'nettype': 'NETWORK_WIFI',
        },
        'req': {
          'module': 'music.search.SearchCgiService',
          'method': 'DoSearchForQQMusicLite',
          'param': {
            'query': keyword,
            'search_type': 0,
            'num_per_page': limit,
            'page_num': page,
            'nqc_flag': 0,
            'grp': 1,
          },
        },
      },
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)',
        },
      ),
    );

    if (response.data['code'] != 0 || response.data['req']['code'] != 0) {
      return [];
    }

    final body = response.data['req']['data']['body'];
    if (body == null || body['item_song'] == null) {
      return [];
    }

    final songs = body['item_song'] as List;
    return _handleTXResult(songs);
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return [];
  }
}

List<Map<String, dynamic>> _handleTXResult(List songs) {
  try {
    return songs.map((song) {
      final types = [];
      final typesMap = {};

      if (song['file']['size_128mp3'] != 0) {
        final size = FormatUtils.formatSize(song['file']['size_128mp3']);
        types.add({'type': '128k', 'size': size});
        typesMap['128k'] = {'size': size};
      }
      if (song['file']['size_320mp3'] != 0) {
        final size = FormatUtils.formatSize(song['file']['size_320mp3']);
        types.add({'type': '320k', 'size': size});
        typesMap['320k'] = {'size': size};
      }
      if (song['file']['size_flac'] != 0) {
        final size = FormatUtils.formatSize(song['file']['size_flac']);
        types.add({'type': 'flac', 'size': size});
        typesMap['flac'] = {'size': size};
      }
      if (song['file']['size_hires'] != 0) {
        final size = FormatUtils.formatSize(song['file']['size_hires']);
        types.add({'type': 'flac24bit', 'size': size});
        typesMap['flac24bit'] = {'size': size};
      }
      if (song['file']['size_dolby'] != 0) {
        final size = FormatUtils.formatSize(song['file']['size_dolby']);
        types.add({'type': 'dolby', 'size': size});
        typesMap['dolby'] = {'size': size};
      }
      if (song['file']['size_new'] != null) {
        if (song['file']['size_new'][0] != null &&
            song['file']['size_new'][0] != 0) {
          final size = FormatUtils.formatSize(song['file']['size_new'][0]);
          types.add({'type': 'master', 'size': size});
          typesMap['master'] = {'size': size};
        }
        if (song['file']['size_new'][1] != null &&
            song['file']['size_new'][1] != 0) {
          final size = FormatUtils.formatSize(song['file']['size_new'][1]);
          types.add({'type': 'effect', 'size': size});
          typesMap['effect'] = {'size': size};
        }
        if (song['file']['size_new'][2] != null &&
            song['file']['size_new'][2] != 0) {
          final size = FormatUtils.formatSize(song['file']['size_new'][2]);
          types.add({'type': 'effect_plus', 'size': size});
          typesMap['effect_plus'] = {'size': size};
        }
      }

      return {
        'title': song['name'],
        'artist': _formatSinger(song['singer']),
        'album': song['album']['name'],
        'albumId': song['album']['mid'],
        'songmid': song['mid'],
        'source': 'tx',
        'interval': FormatUtils.formatPlayTime(song['interval']),
        'img': _getAlbumImg(song['album']['mid'], song['singer']),
        'types': types,
        '_types': typesMap,
        'typeUrl': {},
      };
    }).toList();
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
    throw Exception('搜索失败: $e');
  }
}

String _formatSinger(List singers) {
  return singers.map((s) => s['name']).join('、');
}

String _getAlbumImg(String albumMid, List singers) {
  if (albumMid.isEmpty || albumMid == '空') {
    return singers.isNotEmpty
        ? 'https://y.gtimg.cn/music/photo_new/T001R500x500M000${singers[0]['mid']}.jpg'
        : '';
  }
  return 'https://y.gtimg.cn/music/photo_new/T002R500x500M000$albumMid.jpg';
}
