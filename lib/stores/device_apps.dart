import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:kanade/setup.dart';
import 'package:kanade/stores/settings.dart';
import 'package:kanade/utils/debounce.dart';
import 'package:kanade/utils/is_disposed_mixin.dart';
import 'package:kanade/utils/stringify_uri_location.dart';
import 'package:kanade/utils/throttle.dart';
import 'package:nanoid/async.dart';
import 'package:shared_storage/shared_storage.dart';
import 'package:string_similarity/string_similarity.dart';

mixin DeviceAppsStoreConsumer<T extends StatefulWidget> on State<T> {
  DeviceAppsStore? _store;
  DeviceAppsStore get store => _store ??= getIt<DeviceAppsStore>();

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _store = null; // Refresh store instance when updating the widget
  }
}

class ApkExtraction {
  final File? apk;
  final Result result;

  const ApkExtraction(this.apk, this.result);
}

class MultipleApkExtraction {
  /// You can analyze each extraction individually
  final List<ApkExtraction> extractions;

  /// Overall result based on [extractions] results
  MultipleResult get result {
    final permissionWasDenied =
        extractions.any((extraction) => extraction.result.permissionWasDenied);

    if (permissionWasDenied) return MultipleResult.permissionDenied;

    final successfulExtractionsCount =
        extractions.where((extraction) => extraction.result.success).length;

    if (successfulExtractionsCount == 0) {
      return MultipleResult.allFailed;
    }

    if (successfulExtractionsCount == extractions.length) {
      return MultipleResult.allExtracted;
    }

    return MultipleResult.someFailed;
  }

  const MultipleApkExtraction(this.extractions);
}

class Result {
  final int value;

  const Result(this.value);

  static const extracted = Result(0);
  static const permissionDenied = Result(1);
  static const permissionRestricted = Result(2);
  static const notAllowed = Result(3);

  /// Happy end, apk extracted successfully
  bool get success => value == 0;

  /// User denied permission
  bool get permissionWasDenied => value == 1;

  /// Permission restricted, usually by parent control OS feature
  bool get restrictedPermission => value == 2;

  /// Extraction not permitted,
  /// usually restricted by OS or some protected package
  bool get extractionNotAllowed => value == 3;
}

class MultipleResult {
  final int value;

  const MultipleResult(this.value);

  static const allExtracted = MultipleResult(0);
  static const allFailed = MultipleResult(1);
  static const someFailed = MultipleResult(2);
  static const permissionDenied = MultipleResult(3);

  /// Happy end, all apk's extracted successfully
  bool get success => value == 0;

  /// All apk's extractions failed due one or more reasons
  bool get failed => value == 1;

  /// Some apk's failed but others was successfully extracted
  bool get someMayFailed => value == 2;

  /// User denied permission
  bool get permissionWasDenied => value == 3;
}

class ApplicationSearchResult implements Comparable<ApplicationSearchResult> {
  const ApplicationSearchResult({required this.app, required this.text});

  final String text;
  final Application app;

  String get _rawRegex {
    final matcher = text.substring(0, text.length - 1).split('').join('.*');
    final ending = text[text.length - 1];

    return matcher + ending;
  }

  RegExp get _regex => RegExp(_rawRegex, caseSensitive: false);

  /// Checks if [source] contains all the characters of [text] in the correct order
  ///
  /// Example:
  /// ```
  /// hasMatch('abcdef', 'adf') // true
  /// hasMatch('dbcaef', 'adf') // false
  /// ```
  bool _hasWildcardMatch() {
    return _regex.hasMatch(source);
  }

  bool hasMatch() {
    return _hasWildcardMatch();
  }

  String get source {
    return [app.appName, app.packageName].join(' ').toLowerCase();
  }

  double get similarity {
    return text.similarityTo(source);
  }

  @override
  int compareTo(ApplicationSearchResult other) {
    if (text != other.text) return 0;

    if (similarity == other.similarity) {
      return 0;
    } else if (similarity > other.similarity) {
      return 1;
    } else {
      return -1;
    }
  }
}

class DeviceAppsStore extends ChangeNotifier with IsDisposedMixin {
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

  /// Whether loading device applications or not
  bool isLoading = false;
  int? totalPackagesCount;
  int? get loadedPackagesCount => isLoading ? apps.length : totalPackagesCount;
  bool get fullyLoaded =>
      !isLoading && loadedPackagesCount == totalPackagesCount;

  void Function(void Function()) throttle = throttleIt1s();

  /// Load all device packages
  ///
  /// You need call this method before any action
  Future<void> loadPackages() async {
    isLoading = true;

    notifyListeners();

    totalPackagesCount = await DeviceApps.getInstalledPackagesCount();

    final appsStream = DeviceApps.streamInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: true,
    );

    appsStream.listen(
      (app) {
        apps.add(app);

        throttle(() {
          if (!isDisposed) {
            notifyListeners();
          }
        });
      },
      onDone: () {
        isLoading = false;
        notifyListeners();
      },
    );
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
  List<Application> get displayableApps =>
      _searchText != null ? results.map((e) => e.app).toList() : apps;

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

  static const kApkMimeType = 'application/vnd.android.package-archive';

  /// Extract Apk of a [package]
  Future<ApkExtraction> extractApk(Application package, {Uri? folder}) async {
    final apkFile = File(package.apkFilePath);
    final id = await nanoid(kIdLength);

    final apkFilename =
        '${package.appName}_${package.packageName}_${package.versionCode}_$id';

    if (folder == null) {
      await _settingsStore.requestExportLocationIfNotSet();
    }

    final parentFolder =
        folder ?? await _settingsStore.getAndSetExportLocationIfItExists();

    if (parentFolder != null) {
      final createdFile = await createFile(
        parentFolder,
        mimeType: kApkMimeType,
        displayName: apkFilename,
        bytes: await apkFile.readAsBytes(),
      );

      if (createdFile != null) {
        return ApkExtraction(
          File(stringifyDocumentUri(createdFile.uri)!),
          Result.extracted,
        );
      }
    }

    return ApkExtraction(apkFile, Result.permissionDenied);
  }

  Future<Uri?> requestExportLocation() async {
    await _settingsStore.requestExportLocationIfNotSet();

    return _settingsStore.exportLocation;
  }

  SettingsStore get _settingsStore => getIt<SettingsStore>();

  /// Extract Apk of all [selected] apps
  Future<MultipleApkExtraction> extractSelectedApks() async {
    final extractions = <ApkExtraction>[];

    final folder = await requestExportLocation();

    if (folder != null) {
      for (final selected in selected) {
        extractions.add(await extractApk(selected, folder: folder));
      }

      return MultipleApkExtraction(extractions);
    } else {
      return const MultipleApkExtraction([]);
    }
  }

  /// Verify if a given [package] is selected
  bool isSelected(Application package) => selected.contains(package);

  void disableSearch() {
    _searchText = null;
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

  bool get isSearchMode => _searchText != null;

  List<ApplicationSearchResult> get results {
    if (_searchText == null) return [];

    final filtered = apps
        .map((app) => ApplicationSearchResult(app: app, text: _searchText!))
        .where((result) => result.hasMatch())
        .toList()
      ..sort((a, z) => z.compareTo(a));

    return filtered;
  }

  String? _searchText;

  final debounceSearch = debounceIt200ms();

  /// Add all matched apps to [results] array if any
  ///
  /// This method will disable search if [text] is empty by default
  void search(String text) {
    _searchText = text;

    if (text.isEmpty) {
      _searchText = null;
    }

    debounceSearch(() => notifyListeners());
  }
}
