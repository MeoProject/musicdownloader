import 'package:dio/dio.dart';
import './utils/eapiencrypt.dart';
import 'package:flutter/foundation.dart';
import '../../utils/format_utils.dart';

final Dio dio = Dio();

Future<List<Map<String, dynamic>>> searchWY(String keyword, int limit,
    {int page = 1}) async {
  try {
    final response = await dio.post(
      'https://interface.music.163.com/eapi/batch',
      data: eapi('/api/cloudsearch/pc', {
        's': keyword,
        'type': 1,
        'total': page == 1,
        'limit': limit,
        'offset': page - 1 * limit,
      }),
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36',
          'origin': 'https://music.163.com'
        },
      ),
    );

    if (response.statusCode != 200 || response.data['code'] != 200) {
      return [];
    }

    final songs = response.data['result']['songs'] as List;
    return _handleWYResult(songs);
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return [];
  }
}

Future<List<Map<String, dynamic>>> _handleWYResult(List songs) async {
  return await Future.wait(songs.map((song) async {
    final qualityResponse = await dio.get(
      'https://music.163.com/api/song/music/detail/get',
      queryParameters: {'songId': song['id']},
    );

    final types = [];
    final typesMap = {};

    if (qualityResponse.data['code'] == 200) {
      final quality = qualityResponse.data['data'];

      if (quality['jm'] != null && quality['jm']['size'] is int) {
        final size = FormatUtils.formatSize(quality['jm']['size']);
        types.add({'type': 'master', 'size': size});
        typesMap['master'] = {'size': size};
      }
      if (quality['db'] != null && quality['db']['size'] is int) {
        final size = FormatUtils.formatSize(quality['db']['size']);
        types.add({'type': 'dolby', 'size': size});
        typesMap['dolby'] = {'size': size};
      }
      if (quality['sk'] != null && quality['sk']['size'] is int) {
        final size = FormatUtils.formatSize(quality['sk']['size']);
        types.add({'type': 'sky', 'size': size});
        typesMap['sky'] = {'size': size};
      }
      if (quality['hr'] != null && quality['hr']['size'] is int) {
        final size = FormatUtils.formatSize(quality['hr']['size']);
        types.add({'type': 'flac24bit', 'size': size});
        typesMap['flac24bit'] = {'size': size};
      }
      if (quality['sq'] != null && quality['sq']['size'] is int) {
        final size = FormatUtils.formatSize(quality['sq']['size']);
        types.add({'type': 'flac', 'size': size});
        typesMap['flac'] = {'size': size};
      }
      if (quality['h'] != null && quality['h']['size'] is int) {
        final size = FormatUtils.formatSize(quality['h']['size']);
        types.add({'type': '320k', 'size': size});
        typesMap['320k'] = {'size': size};
      }
      if ((quality['m'] != null && quality['m']['size'] is int) ||
          (quality['l'] != null && quality['l']['size'] is int)) {
        final size = FormatUtils.formatSize(
            quality['m'] != null ? quality['m']['size'] : quality['l']['size']);
        types.add({'type': '128k', 'size': size});
        typesMap['128k'] = {'size': size};
      }
    }

    return {
      'title': song['name'],
      'artist': _formatWYSinger(song['ar']),
      'album': song['al']['name'],
      'albumId': song['al']['id'].toString(),
      'songmid': song['id'].toString(),
      'source': 'wy',
      'interval': FormatUtils.formatPlayTime(song['dt'] ~/ 1000),
      'img': song['al']['picUrl'],
      'types': types,
      '_types': typesMap,
      'typeUrl': {},
    };
  }));
}

String _formatWYSinger(List artists) {
  return artists.map((ar) => ar['name']).join('、');
}
