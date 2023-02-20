import 'dart:io';
import 'dart:math';

import 'package:device_packages/device_packages.dart';

String getFileSizeString(int bytes, {int decimals = 0}) {
  const List<String> suffixes = <String>['B', 'KB', 'MB', 'GB', 'TB'];

  if (bytes == 0) return '0${suffixes[0]}';

  final int i = (log(bytes) / log(1024)).floor();

  return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + suffixes[i];
}

extension FormattedBytes on num {
  String formatBytes() => getFileSizeString(this ~/ 1);
}

extension ApplicationSize on PackageInfo {
  int get size {
    try {
      return File(installerPath!).lengthSync();
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 2) {
        throw AppIsNotAvailable();
      } else {
        rethrow;
      }
    }
  }
}

class AppIsNotAvailable implements Exception {}
