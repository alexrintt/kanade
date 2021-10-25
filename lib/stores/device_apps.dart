import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:kanade/setup.dart';
import 'package:nanoid/async.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

mixin DeviceAppsStoreConsumer<T extends StatefulWidget> on State<T> {
  final store = getIt<DeviceAppsStore>();
}

class ApkExtraction {
  final File? apk;
  final Result result;

  const ApkExtraction(this.apk, this.result);
}

class Result {
  final int value;

  const Result(this.value);

  static const extracted = Result(0);
  static const permissionDenied = Result(1);
  static const permissionRestricted = Result(2);

  bool get success => value == 0;

  bool get permissionWasDenied => value == 1;

  bool get restrictedPermission => value == 2;
}

class DeviceAppsStore extends ChangeNotifier {
  /// Id length to avoid filename conflict on extract Apk
  static const kIdLength = 5;

  /// Max tries count to export Apk
  static const kMaxTriesCount = 10;

  /// List of all device applications
  /// - Include system apps
  /// - Include app icons
  final apps = <Application>[];

  /// List of all selected applications
  final selected = <Application>{};

  /// List of all search results
  /// If null, has no query
  /// If empty, has no results
  /// Otherwise hold all results
  List<Application>? results;

  /// Whether loading device applications or not
  bool isLoading = false;

  /// Load all device packages
  ///
  /// You need call this method before any action
  Future<void> loadPackages() async {
    isLoading = true;

    notifyListeners();

    final deviceApps = await DeviceApps.getInstalledApplications(
      includeSystemApps: true,
      includeAppIcons: true,
    );

    isLoading = false;

    apps.addAll(deviceApps);

    notifyListeners();
  }

  /// Mark all apps as unselected
  void clearSelection() {
    selected.clear();
    notifyListeners();
  }

  void restoreToDefault() {
    clearSelection();
    disableSearch();
    notifyListeners();
  }

  /// Packages to be rendered on the screen
  List<Application> get displayableApps => results != null ? results! : apps;

  /// Return [true] if all [displayableApps] are selected
  bool get isAllSelected => displayableApps.length == selected.length;

  /// Add [package] to the [selected] Set
  void toggleSelect(Application package) {
    if (selected.contains(package)) {
      selected.remove(package);
    } else {
      selected.add(package);
    }

    notifyListeners();
  }

  /// Extract Apk of a [package]
  Future<ApkExtraction> extractApk(Application package,
      [int tryCount = 0]) async {
    final apkFile = File(package.apkFilePath);
    final id = await nanoid(kIdLength);

    final apkFilename = '${package.appName} ${package.packageName} $id.apk';

    await Permission.storage.request();

    final status = await Permission.storage.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      return const ApkExtraction(null, Result.permissionDenied);
    } else if (status.isRestricted || status.isLimited) {
      return const ApkExtraction(null, Result.permissionRestricted);
    } else if (status.isGranted) {
      const kRootFolder = 'Kanade';
      final appDir = Directory('storage/emulated/0/$kRootFolder');

      if (!appDir.existsSync()) {
        await appDir.create();
      }

      final exportedApkFile = File(join(appDir.path, apkFilename));

      if (exportedApkFile.existsSync()) {
        if (tryCount > kMaxTriesCount) {
          throw Exception('Too many exported Apk\'s');
        }

        /// Try again, with another id
        return extractApk(package, tryCount + 1);
      } else {
        final extractedApk = await apkFile.copy(exportedApkFile.path);

        return ApkExtraction(extractedApk, Result.extracted);
      }
    }

    throw Exception('Invalid permission result: $status');
  }

  /// Extract Apk of all [selected] apps
  Future<void> extractSelectedApks() async {
    for (final selected in selected) {
      await extractApk(selected);
    }
  }

  /// Verify if a given [package] is selected
  bool isSelected(Application package) => selected.contains(package);

  /// Set [results] as [null] and show all [apps] as [displayableApps]
  void disableSearch() {
    results = null;
    notifyListeners();
  }

  /// Select all [displayableApps], otherwise mark all as unselected
  void toggleSelectAll() {
    if (isAllSelected) {
      selected.clear();
    } else {
      selected
        ..clear()
        ..addAll(displayableApps);
    }

    notifyListeners();
  }

  /// Add all matched apps to [results] array if any
  ///
  /// This method will disable search if [text] is empty by default
  void search(String text) {
    bool hasMatch(Application app) {
      final source = [app.appName, app.packageName].join(' ');

      return _hasWildcardMatch(source, text);
    }

    results = [];

    if (text.isEmpty) {
      disableSearch();
    } else {
      results = apps.where(hasMatch).toList();
    }

    notifyListeners();
  }

  /// Checks if [source] contains all the characters of [text] in the correct order
  ///
  /// Example:
  /// ```
  /// hasMatch('abcdef', 'adf') // true
  /// hasMatch('dbcaef', 'adf') // false
  /// ```
  bool _hasWildcardMatch(String source, String text) {
    final regexp = text.split('').join('.*');

    return RegExp(regexp).hasMatch(source);
  }
}
