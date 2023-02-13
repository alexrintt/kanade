import 'dart:io';
import 'dart:math';

import 'package:device_apps/device_apps.dart';

String getFileSizeString(int bytes, {int decimals = 0}) {
  const List<String> suffixes = <String>['B', 'KB', 'MB', 'GB', 'TB'];

  if (bytes == 0) return '0${suffixes[0]}';

  final int i = (log(bytes) / log(1024)).floor();

  return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + suffixes[i];
}

extension FormattedBytes on num {
  String formatBytes() => getFileSizeString(this ~/ 1);
}

extension ApplicationSize on Application {
  int get size {
    try {
      return File(apkFilePath).lengthSync();
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 2) {
        print('This file was uninstalled');
      } else {}
      return 0;
    }
  }
}
