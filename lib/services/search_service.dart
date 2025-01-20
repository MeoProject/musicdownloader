import 'package:dio/dio.dart';
import '../utils/format_utils.dart';
import './custom_transformer.dart';
import '../utils/md5_utils.dart';
import 'package:logging/logging.dart';

final log = Logger("Search");

class SearchService {
  final Dio http = Dio(BaseOptions(
    validateStatus: (status) => true,
  ))
    ..transformer = CustomTransformer();
  static const int limit = 50;

  Future<List<Map<String, dynamic>>> search(
      String keyword, String engine) async {
    switch (engine) {
      case 'tx':
        return await _searchTX(keyword);
      case 'wy':
        return await _searchWY(keyword);
      case 'mg':
        return await _searchMG(keyword);
      case 'kg':
        return await _searchKG(keyword);
      case 'kw':
        return await _searchKW(keyword);
      default:
        throw Exception('不支持的搜索引擎');
    }
  }

  Future<String?> getDownloadUrl(
      String source, String songid, String quality) async {
    try {
      final response = await http.get("https://lxmusic.ikunshare.com/url",
          queryParameters: {
            "source": source,
            "songId": songid,
            "quality": quality,
          },
          options: Options(headers: {"X-Request-Key": "IKUNSOURCE_PRIVATE"}));
      if (response.statusCode != 200 || response.data['code'] != 0) {
        final errormsg = response.data['msg'];
        throw Exception('链接获取失败：$errormsg');
      }
      return response.data['data'].toString();
    } catch (e) {
      log.severe('链接获取失败, $source, $songid, $quality');
      return null;
    }
  }

  Future<String?> getKGImage(Map<String, dynamic> songInfo) async {
    final response = await http.post(
      'http://media.store.kugou.com/v1/get_res_privilege',
      data: {
        'appid': 1001,
        'area_code': '1',
        'behavior': 'play',
        'clientver': '9020',
        'need_hash_offset': 1,
        'relate': 1,
        'resource': [
          {
            'album_audio_id': songInfo['audioId'] ?? songInfo['songmid'],
            'album_id': songInfo['albumId'],
            'hash': songInfo['hash'],
            'id': 0,
            'name': '${songInfo['singer']} - ${songInfo['name']}.mp3',
            'type': 'audio',
          },
        ],
        'token': '',
        'userid': 2626431536,
        'vip': 1,
      },
      options: Options(
        headers: {
          'KG-RC': 1,
          'KG-THash': 'expand_search_manager.cpp:852736169:451',
          'User-Agent': 'KuGou2012-9020-ExpandSearchManager',
        },
      ),
    );

    if (response.data['error_code'] == 0) {
      final info = response.data['data'][0]['info'];
      final img = info['imgsize'] != null
          ? info['image'].replaceAll('{size}', info['imgsize'][0])
          : info['image'];
      if (img != null) {
        return img;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _searchTX(String keyword,
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
        throw Exception('搜索失败');
      }

      final songs = response.data['req']['data']['body']['item_song'] as List;
      return _handleTXResult(songs);
    } catch (e) {
      throw Exception('搜索失败: $e');
    }
  }

  List<Map<String, dynamic>> _handleTXResult(List songs) {
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
      if (song['file']['size_new'] != null &&
          song['file']['size_new'][0] != 0) {
        final size = FormatUtils.formatSize(song['file']['size_new'][0]);
        types.add({'type': 'master', 'size': size});
        typesMap['master'] = {'size': size};
      }
      if (song['file']['size_new'] != null &&
          song['file']['size_new'][1] != 0) {
        final size = FormatUtils.formatSize(song['file']['size_new'][1]);
        types.add({'type': 'effect', 'size': size});
        typesMap['effect'] = {'size': size};
      }
      if (song['file']['size_new'] != null &&
          song['file']['size_new'][2] != 0) {
        final size = FormatUtils.formatSize(song['file']['size_new'][2]);
        types.add({'type': 'effect_plus', 'size': size});
        typesMap['effect_plus'] = {'size': size};
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

  Future<List<Map<String, dynamic>>> _searchWY(String keyword,
      {int page = 1}) async {
    try {
      final response = await http.get(
        'https://api.csm.sayqz.com/cloudsearch',
        queryParameters: {
          'keywords': keyword,
          'limit': limit,
          'offset': ((page - 1) * limit).toString(),
        },
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36'
          },
        ),
      );

      if (response.data['code'] != 200) {
        throw Exception('搜索失败');
      }

      final songs = response.data['result']['songs'] as List;
      return _handleWYResult(songs);
    } catch (e) {
      throw Exception('搜索失败: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _handleWYResult(List songs) async {
    return await Future.wait(songs.map((song) async {
      final qualityResponse = await http.get(
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
          final size = FormatUtils.formatSize(quality['m'] != null
              ? quality['m']['size']
              : quality['l']['size']);
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

  Future<List<Map<String, dynamic>>> _searchMG(String keyword,
      {int page = 1}) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final deviceId = '963B7AA0D21511ED807EE5846EC87D20';
    final signatureMd5 = '6cdc72a439cef99a3418d2a78aa28c73';

    final sign = generateMd5(
        '$keyword${signatureMd5}yyapp2d16148780a1dcc7408e06336b98cfd50$deviceId$time');

    try {
      final response = await http.get(
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
        throw Exception(response.data['info'] ?? '搜索失败');
      }

      final songResultData = response.data['songResultData']!;
      return _handleMGResult(songResultData['resultList']);
    } catch (e) {
      throw Exception('搜索失败: $e');
    }
  }

  List<Map<String, dynamic>> _handleMGResult(List resultList) {
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
          'lrc': null,
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

  Future<List<Map<String, dynamic>>> _searchKG(String keyword,
      {int page = 1}) async {
    try {
      final response = await http.get(
        'https://songsearch.kugou.com/song_search_v2',
        queryParameters: {
          'keyword': keyword,
          'page': page,
          'pagesize': limit,
          'userid': '0',
          'clientver': '',
          'platform': 'WebFilter',
          'filter': '2',
          'iscorrection': '1',
          'privilege_filter': '0',
          'area_code': '1'
        },
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3',
          },
        ),
      );

      if (response.data['error_code'] != 0) {
        throw Exception('搜索失败');
      }

      final songs = response.data['data']['lists'] as List;
      return _handleKGResult(songs);
    } catch (e) {
      throw Exception('搜索失败: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _handleKGResult(List songs) async {
    final list = <Map<String, dynamic>>[];
    final ids = <String>{};

    for (var song in songs) {
      final key = '${song['Audioid']}${song['FileHash']}';
      if (ids.contains(key)) continue;
      ids.add(key);

      final types = [];
      final typesMap = {};

      if (song['FileSize'] != 0) {
        final size = FormatUtils.formatSize(song['FileSize']);
        types.add({'type': '128k', 'size': size, 'hash': song['FileHash']});
        typesMap['128k'] = {'size': size, 'hash': song['FileHash']};
      }
      if (song['HQFileSize'] != 0) {
        final size = FormatUtils.formatSize(song['HQFileSize']);
        types.add({'type': '320k', 'size': size, 'hash': song['HQFileHash']});
        typesMap['320k'] = {'size': size, 'hash': song['HQFileHash']};
      }
      if (song['SQFileSize'] != 0) {
        final size = FormatUtils.formatSize(song['SQFileSize']);
        types.add({'type': 'flac', 'size': size, 'hash': song['SQFileHash']});
        typesMap['flac'] = {'size': size, 'hash': song['SQFileHash']};
      }
      if (song['ResFileSize'] != 0) {
        final size = FormatUtils.formatSize(song['ResFileSize']);
        types.add(
            {'type': 'flac24bit', 'size': size, 'hash': song['ResFileHash']});
        typesMap['flac24bit'] = {'size': size, 'hash': song['ResFileHash']};
      }

      final img = await getKGImage({
        'songmid': song['Audioid'],
        'audioId': song['FileHash'],
        'albumId': song['AlbumID'],
        'hash': song['FileHash'],
        'singer': song['Singers'].map((s) => s['name']).join('、'),
        'name': song['SongName'],
      });

      list.add({
        'title': song['SongName'],
        'artist': _formatKGSinger(song['Singers']),
        'album': song['AlbumName'],
        'albumId': song['AlbumID'],
        'songmid': song['Audioid'],
        'source': 'kg',
        'interval': FormatUtils.formatPlayTime(song['Duration']),
        'img': img,
        'lrc': null,
        'hash': song['FileHash'],
        'types': types,
        '_types': typesMap,
        'typeUrl': {},
      });

      if (song['Grp'] != null) {
        for (var groupSong in song['Grp']) {
          final groupKey = '${groupSong['Audioid']}${groupSong['FileHash']}';
          if (ids.contains(groupKey)) continue;
          ids.add(groupKey);

          list.add(_handleSingleKGSong(groupSong));
        }
      }
    }
    return list;
  }

  Map<String, dynamic> _handleSingleKGSong(Map<String, dynamic> song) {
    final types = [];
    final typesMap = {};

    if (song['FileSize'] != 0) {
      final size = FormatUtils.formatSize(song['FileSize']);
      types.add({'type': '128k', 'size': size, 'hash': song['FileHash']});
      typesMap['128k'] = {'size': size, 'hash': song['FileHash']};
    }
    if (song['HQFileSize'] != 0) {
      final size = FormatUtils.formatSize(song['HQFileSize']);
      types.add({'type': '320k', 'size': size, 'hash': song['HQFileHash']});
      typesMap['320k'] = {'size': size, 'hash': song['HQFileHash']};
    }
    if (song['SQFileSize'] != 0) {
      final size = FormatUtils.formatSize(song['SQFileSize']);
      types.add({'type': 'flac', 'size': size, 'hash': song['SQFileHash']});
      typesMap['flac'] = {'size': size, 'hash': song['SQFileHash']};
    }
    if (song['ResFileSize'] != 0) {
      final size = FormatUtils.formatSize(song['ResFileSize']);
      types.add(
          {'type': 'flac24bit', 'size': size, 'hash': song['ResFileHash']});
      typesMap['flac24bit'] = {'size': size, 'hash': song['ResFileHash']};
    }

    return {
      'title': song['SongName'],
      'artist': _formatKGSinger(song['Singers']),
      'album': song['AlbumName'],
      'albumId': song['AlbumID'],
      'songmid': song['Audioid'],
      'source': 'kg',
      'interval': FormatUtils.formatPlayTime(song['Duration']),
      'img': null,
      'lrc': null,
      'hash': song['FileHash'],
      'types': types,
      '_types': typesMap,
      'typeUrl': {},
    };
  }

  String _formatKGSinger(List singers) {
    return singers.map((s) => s['name']).join('、');
  }

  Future<String?> _getKWPic(String songmid) async {
    try {
      final response = await http.get(
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

  Future<List<Map<String, dynamic>>> _searchKW(String keyword,
      {int page = 1}) async {
    try {
      final response = await http.get(
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
        throw Exception('搜索失败');
      }

      final songs = response.data['abslist'] as List;
      return _handleKWResult(songs);
    } catch (e) {
      throw Exception('搜索失败: $e');
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
}
