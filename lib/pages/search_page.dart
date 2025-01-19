import 'package:flutter/material.dart';
import 'package:musicdownloader/services/download_service.dart';
import '../services/search_service.dart';
import '../state/app_state.dart';
import '../i18n/quality_translations.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  bool isLoading = false;

  Future<void> performSearch() async {
    if (searchController.text.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final appState = AppStateProvider.of(context);
      ScaffoldMessenger.of(context);
      final results = await _searchService.search(
        searchController.text,
        appState.currentEngine,
      );

      if (!mounted) return;
      appState.setSearchResults(results);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('搜索失败: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _getEngineIcon(String currentEngine) {
    switch (currentEngine) {
      case 'tx':
        return Image.asset('assets/images/tx_icon.png', width: 24, height: 24);
      case 'wy':
        return Image.asset('assets/images/wy_icon.png', width: 24, height: 24);
      case 'mg':
        return Image.asset('assets/images/mg_icon.png', width: 24, height: 24);
      case 'kg':
        return Image.asset('assets/images/kg_icon.png', width: 24, height: 24);
      case 'kw':
        return Image.asset('assets/images/kw_icon.png', width: 24, height: 24);
      default:
        return Icon(Icons.music_note);
    }
  }

  void _showEngineSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final appState = AppStateProvider.of(context);
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('QQ音乐'),
                leading: Image.asset('assets/images/tx_icon.png',
                    width: 24, height: 24),
                onTap: () {
                  appState.setCurrentEngine('tx');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('网易云音乐'),
                leading: Image.asset('assets/images/wy_icon.png',
                    width: 24, height: 24),
                onTap: () {
                  appState.setCurrentEngine('wy');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('咪咕音乐'),
                leading: Image.asset('assets/images/mg_icon.png',
                    width: 24, height: 24),
                onTap: () {
                  appState.setCurrentEngine('mg');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('酷狗音乐'),
                leading: Image.asset('assets/images/kg_icon.png',
                    width: 24, height: 24),
                onTap: () {
                  appState.setCurrentEngine('kg');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('酷我音乐'),
                leading: Image.asset('assets/images/kw_icon.png',
                    width: 24, height: 24),
                onTap: () {
                  appState.setCurrentEngine('kw');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQualitySelector(Map<String, dynamic> song) {
    final types = (song['types'] as List)
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
    final sortedTypes = QualityTranslations.sortQualities(
        types.map((t) => t['type'] as String).toList());

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  '${song['title']} - ${song['artist']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Divider(),
              ...sortedTypes.map((type) {
                final typesMap =
                    Map<String, dynamic>.from(song['_types'] as Map);
                final typeInfo =
                    Map<String, dynamic>.from(typesMap[type] as Map);
                return ListTile(
                  dense: true,
                  title: Text(QualityTranslations.qualityNamesZh[type] ?? ''),
                  trailing: Text(typeInfo['size']?.toString() ?? ''),
                  onTap: () async {
                    Navigator.pop(context);
                    final downloadService = DownloadService();
                    if (song['source'] == 'kg') {
                      await downloadService.downloadMusic(
                        song['source'],
                        song['hash'],
                        type,
                        song,
                        context,
                      );
                    } else {
                      await downloadService.downloadMusic(
                        song['source'],
                        song['songmid'],
                        type,
                        song,
                        context,
                      );
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualityTags(Map<String, dynamic> result) {
    final types =
        (result['types'] as List).map((t) => t['type'] as String).toList();
    final sortedTypes = QualityTranslations.sortQualities(types);

    if (sortedTypes.isEmpty) return SizedBox.shrink();

    final highestQuality = sortedTypes.last;
    final translation = QualityTranslations.qualityNames[highestQuality];

    if (translation == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        translation,
        style: TextStyle(
          fontSize: 10,
          color: highestQuality == '128k'
              ? Colors.black
              : highestQuality == '320k'
                  ? Colors.brown
                  : Colors.green,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _getEngineIcon(appState.currentEngine),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: '输入歌名或歌手',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => performSearch(),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: performSearch,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: appState.searchResults.length,
                  itemBuilder: (context, index) {
                    final result = appState.searchResults[index];
                    return Card(
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(result['title'] ?? ''),
                            ),
                            _buildQualityTags(result),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(result['artist'] ?? ''),
                            Text(result['album'] ?? ''),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.download),
                          onPressed: () => _showQualitySelector(result),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEngineSelector,
        tooltip: '切换搜索引擎',
        child: Icon(Icons.swap_horiz),
      ),
    );
  }
}
