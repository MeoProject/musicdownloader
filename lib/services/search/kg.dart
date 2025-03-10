import 'package:dio/dio.dart';
import '../../utils/format_utils.dart';

final Dio dio = Dio();

Future<String?> getKGImage(Map<String, dynamic> songInfo) async {
  final response = await dio.post(
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

Future<List<Map<String, dynamic>>> searchKG(String keyword, int limit,
    {int page = 1}) async {
  try {
    final response = await dio.get(
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
        'privilege_filter': '0', // Corrected typo from 'privilege_filter'
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

    print('API Response: ${response.data}');

    if (response.data is! Map<String, dynamic> ||
        response.data['data'] is! Map<String, dynamic> ||
        response.data['data']['lists'] is! List) {
      throw Exception('Unexpected API response structure');
    }

    List musiclist = response.data['data']['lists'];

    return _handleKGResult(musiclist);
  } catch (e) {
    print('Error in searchKG: $e');
    return [];
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
      'songmid': song['Audioid'],
      'source': 'kg',
      'img': img,
      'lrc': null,
      'hash': song['FileHash'],
      'types': types,
      '_types': typesMap,
    });

    if (song['Grp'] != null) {
      for (var groupSong in song['Grp']) {
        final groupKey = '${groupSong['Audioid']}${groupSong['FileHash']}';
        if (ids.contains(groupKey)) continue;
        ids.add(groupKey);

        list.add(await _handleSingleKGSong(groupSong));
      }
    }
  }
  print(list);
  return list;
}

Future<Map<String, dynamic>> _handleSingleKGSong(
    Map<String, dynamic> song) async {
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
    types.add({'type': 'flac24bit', 'size': size, 'hash': song['ResFileHash']});
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

  return {
    'title': song['SongName'],
    'artist': _formatKGSinger(song['Singers']),
    'album': song['AlbumName'],
    'songmid': song['Audioid'],
    'source': 'kg',
    'img': img,
    'lrc': null,
    'hash': song['FileHash'],
    'types': types,
    '_types': typesMap,
  };
}

String _formatKGSinger(List singers) {
  return singers.map((s) => s['name']).join('、');
}
