import './search/kg.dart';
import './search/kw.dart';
import './search/tx.dart';
import './search/mg.dart';
import './search/wy.dart';

const int limit = 50;

Future<List<Map<String, dynamic>>> search(String keyword, String source) async {
  switch (source) {
    case 'tx':
      return await searchTX(keyword, limit);
    case 'wy':
      return await searchWY(keyword, limit);
    case 'mg':
      return await searchMG(keyword, limit);
    case 'kg':
      return await searchKG(keyword, limit);
    case 'kw':
      return await searchKW(keyword, limit);
    default:
      throw Exception('不支持的搜索引擎');
  }
}
