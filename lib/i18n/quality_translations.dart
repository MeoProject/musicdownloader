class QualityTranslations {
  static const Map<String, String> qualityNames = {
    '128k': 'Std',
    '320k': 'HQ',
    'flac': 'SQ',
    'flac24bit': 'Hires',
    'sky': 'Sky',
    'dolby': 'Dolby',
    'effect': 'Effect',
    'effect_plus': 'Effect+',
    'master': 'Master',
  };

  static const Map<String, String> qualityNamesZh = {
    '128k': '普通音质 128K',
    '320k': '高品音质 320K',
    'flac': '无损音质 FLAC',
    'flac24bit': '无损音质 Hires',
    'sky': '沉浸环绕声',
    'dolby': '杜比全景声',
    'effect': '臻品全景声',
    'effect_plus': '臻品全景声2.0',
    'master': '臻品母带',
  };

  static List<String> sortQualities(List<String> qualities) {
    const order = [
      '128k',
      '320k',
      'flac',
      'flac24bit',
      'sky',
      'dolby',
      'effect',
      'effect_plus',
      'master'
    ];

    return List.from(qualities)
      ..sort((a, b) {
        return order.indexOf(a).compareTo(order.indexOf(b));
      });
  }
}
