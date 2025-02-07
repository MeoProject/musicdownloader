import 'package:dio/dio.dart';
import '../../utils/format_utils.dart';

final Dio dio = Dio();

Future<String?> _getKWPic(String songmid) async {
  try {
    final response = await dio.get(
      'http://artistpicserver.kuwo.cn/pic.web',
      queryParameters: {
        'corp': 'kuwo',
        'type': 'rid_pic',
        'pictype': '500',
        'size': '500',
        'rid': songmid,
      },
    );

    final body = response.data.toString();
    return RegExp(r'^http').hasMatch(body) ? body : null;
  } catch (e) {
    return null;
  }
}

Future<List<Map<String, dynamic>>> searchKW(String keyword, int limit,
    {int page = 1}) async {
  try {
    final response = await dio.get(
      'http://search.kuwo.cn/r.s',
      queryParameters: {
        'client': 'kt',
        'all': keyword,
        'pn': page - 1,
        'rn': limit,
        'uid': '794762570',
        'ver': 'kwplayer_ar_9.2.2.1',
        'vipver': '1',
        'show_copyright_off': '1',
        'newver': '1',
        'ft': 'music',
        'cluster': '0',
        'strategy': '2012',
        'encoding': 'utf8',
        'rformat': 'json',
        'vermerge': '1',
        'mobi': '1',
        'issubtitle': '1',
      },
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3',
        },
      ),
    );

    if (response.data['TOTAL'] == '0' || response.data['SHOW'] == '0') {
      return [];
    }

    final songs = response.data['abslist'] as List;
    return _handleKWResult(songs);
  } catch (e) {
    return [];
  }
}

Future<List<Map<String, dynamic>>> _handleKWResult(List songs) {
  return Future.wait(songs.map((song) async {
    final types = [];
    final typesMap = {};

    final infoArr = song['N_MINFO'].split(';');
    for (var info in infoArr) {
      final match =
          RegExp(r'level:(\w+),bitrate:(\d+),format:(\w+),size:([\w.]+)')
              .firstMatch(info);
      if (match != null) {
        switch (match.group(2)) {
          case '4000':
            types.add({'type': 'flac24bit', 'size': match.group(4)});
            typesMap['flac24bit'] = {'size': match.group(4)};
            break;
          case '2000':
            types.add({'type': 'flac', 'size': match.group(4)});
            typesMap['flac'] = {'size': match.group(4)};
            break;
          case '320':
            types.add({'type': '320k', 'size': match.group(4)});
            typesMap['320k'] = {'size': match.group(4)};
            break;
          case '128':
            types.add({'type': '128k', 'size': match.group(4)});
            typesMap['128k'] = {'size': match.group(4)};
            break;
        }
      }
    }

    final songmid = song['MUSICRID'].toString().replaceAll('MUSIC_', '');

    return {
      'title': song['SONGNAME'],
      'artist': song['ARTIST'],
      'album': song['ALBUM'],
      'albumId': song['ALBUMID'],
      'songmid': songmid,
      'source': 'kw',
      'interval': FormatUtils.formatPlayTime(int.parse(song['DURATION'])),
      'img': await _getKWPic(songmid),
      'lrc': null,
      'types': types,
      '_types': typesMap,
      'typeUrl': {},
    };
  })).then((list) => list);
}
