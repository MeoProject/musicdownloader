import 'dart:math';

class FormatUtils {
  static String formatSize(int bytes) {
    if (bytes == 0) return '0 B';
    final sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${sizes[i]}';
  }

  static String formatPlayTime(int seconds) {
    final min = (seconds / 60).floor();
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
