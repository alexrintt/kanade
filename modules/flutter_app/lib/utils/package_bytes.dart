import 'dart:math';

String getFileSizeString(int bytes, {int decimals = 0}) {
  const List<String> suffixes = <String>['B', 'KB', 'MB', 'GB', 'TB'];

  if (bytes == 0) return '0${suffixes[0]}';

  final int i = (log(bytes) / log(1024)).floor();

  return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + suffixes[i];
}

extension FormattedBytes on num {
  String formatBytes() => getFileSizeString(this ~/ 1);
}

class AppIsNotAvailable implements Exception {}
