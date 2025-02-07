import 'package:dio/dio.dart';
import '../../utils/md5_utils.dart';
import '../../utils/format_utils.dart';

final Dio dio = Dio();

Future<List<Map<String, dynamic>>> searchMG(String keyword, int limit,
    {int page = 1}) async {
  final time = DateTime.now().millisecondsSinceEpoch.toString();
  final deviceId = '963B7AA0D21511ED807EE5846EC87D20';
  final signatureMd5 = '6cdc72a439cef99a3418d2a78aa28c73';

  final sign = generateMd5(
      '$keyword${signatureMd5}yyapp2d16148780a1dcc7408e06336b98cfd50$deviceId$time');

  try {
    final response = await dio.get(
      'https://jadeite.migu.cn/music_search/v3/search/searchAll',
      queryParameters: {
        'isCorrect': '0',
        'isCopyright': '1',
        'searchSwitch':
            '{"song":1,"album":0,"singer":0,"tagSong":1,"mvSong":0,"bestShow":1,"songlist":0,"lyricSong":0}',
        'pageSize': limit,
        'text': keyword,
        'pageNo': page,
        'sort': '0',
        'sid': 'USS'
      },
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'uiVersion': 'A_music_3.6.1',
          'deviceId': deviceId,
          'timestamp': time,
          'sign': sign,
          'channel': '0146921',
          'User-Agent':
              'Mozilla/5.0 (Linux; U; Android 11.0.0; zh-cn; MI 11 Build/OPR1.170623.032) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30',
        },
      ),
    );

    if (response.data['code'] != '000000') {
      return [];
    }

    final songResultData = response.data['songResultData']!;
    return _handleMGResult(songResultData['resultList']);
  } catch (e) {
    return [];
  }
}

Future<List<Map<String, dynamic>>> _handleMGResult(List resultList) async {
  final list = <Map<String, dynamic>>[];

  for (var songList in resultList) {
    for (var song in songList) {
      final types = [];
      final typesMap = {};

      if (song['audioFormats'] != null) {
        for (var format in song['audioFormats']) {
          String? size;
          switch (format['formatType']) {
            case 'PQ':
              size = FormatUtils.formatSize(
                  int.tryParse(format['asize'].toString()) ?? 0);
              types.add({'type': '128k', 'size': size});
              typesMap['128k'] = {'size': size};
              break;
            case 'HQ':
              size = FormatUtils.formatSize(
                  int.tryParse(format['asize'].toString()) ?? 0);
              types.add({'type': '320k', 'size': size});
              typesMap['320k'] = {'size': size};
              break;
            case 'SQ':
              size = FormatUtils.formatSize(
                  int.tryParse(format['asize'].toString()) ?? 0);
              types.add({'type': 'flac', 'size': size});
              typesMap['flac'] = {'size': size};
              break;
            case 'ZQ24':
              size = FormatUtils.formatSize(
                  int.tryParse(format['asize'].toString()) ?? 0);
              types.add({'type': 'flac24bit', 'size': size});
              typesMap['flac24bit'] = {'size': size};
              break;
          }
        }
      }

      String? img = song['img3'] ?? song['img2'] ?? song['img1'];
      if (img != null && !img.startsWith('http')) {
        img = 'http://d.musicapp.migu.cn$img';
      }

      final lyricResponse = await Dio().get<String>(song['lrcUrl']);

      list.add({
        'title': song['name'],
        'artist': _formatMGSinger(song['singerList']),
        'album': song['album'],
        'albumId': song['albumId'],
        'songmid': song['songId'],
        'copyrightId': song['copyrightId'],
        'source': 'mg',
        'interval': FormatUtils.formatPlayTime(song['duration']),
        'img': img,
        'lrc': lyricResponse.data,
        'lrcUrl': song['lrcUrl'],
        'mrcUrl': song['mrcurl'],
        'trcUrl': song['trcUrl'],
        'types': types,
        '_types': typesMap,
        'typeUrl': {},
      });
    }
  }
  return list;
}

String _formatMGSinger(List singers) {
  return singers.map((s) => s['name']).join('、');
}
