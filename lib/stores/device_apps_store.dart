import 'dart:async';
import 'dart:io';

import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/async.dart';
import 'package:shared_storage/shared_storage.dart';
import 'package:string_similarity/string_similarity.dart';

import '../setup.dart';
import '../utils/debounce.dart';
import '../utils/is_disposed_mixin.dart';
import '../utils/stringify_uri_location.dart';
import '../utils/throttle.dart';
import 'settings_store.dart';

mixin DeviceAppsStoreMixin<T extends StatefulWidget> on State<T> {
  DeviceAppsStore? _store;
  DeviceAppsStore get store => _store ??= getIt<DeviceAppsStore>();

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _store = null; // Refresh store instance when updating the widget
  }
}

class ApkExtraction {
  const ApkExtraction(this.apk, this.result);

  final File? apk;
  final Result result;
}

class MultipleApkExtraction {
  const MultipleApkExtraction(this.extractions);

  /// You can analyze each extraction individually
  final List<ApkExtraction> extractions;

  /// Overall result based on [extractions] results
  MultipleResult get result {
    final bool permissionWasDenied = extractions.any(
      (ApkExtraction extraction) => extraction.result.permissionWasDenied,
    );

    if (permissionWasDenied) return MultipleResult.permissionDenied;

    final int successfulExtractionsCount = extractions
        .where((ApkExtraction extraction) => extraction.result.success)
        .length;

    if (successfulExtractionsCount == 0) {
      return MultipleResult.allFailed;
    }

    if (successfulExtractionsCount == extractions.length) {
      return MultipleResult.allExtracted;
    }

    return MultipleResult.someFailed;
  }
}

enum Result {
  extracted,
  permissionDenied,
  permissionRestricted,
  notAllowed,
  notFound;

  /// Happy end, apk extracted successfully
  bool get success => this == extracted;

  /// User denied permission
  bool get permissionWasDenied => this == permissionDenied;

  /// Permission restricted, usually by parent control OS feature
  bool get restrictedPermission => this == permissionRestricted;

  /// Extraction not permitted,
  /// usually restricted by OS or some protected package
  bool get extractionNotAllowed => this == notAllowed;

  /// Tried to extract either an invalid or an uninstalled app.
  bool get wasNotFound => this == notFound;
}

class MultipleResult {
  const MultipleResult(this.value);
  final int value;

  static const MultipleResult allExtracted = MultipleResult(0);
  static const MultipleResult allFailed = MultipleResult(1);
  static const MultipleResult someFailed = MultipleResult(2);
  static const MultipleResult permissionDenied = MultipleResult(3);

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
  final PackageInfo app;

  String get _rawRegex {
    final String matcher =
        text.substring(0, text.length - 1).split('').join('.*');
    final String ending = text[text.length - 1];

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

  bool hasMatch() => _hasWildcardMatch();

  String get source {
    return <String>[app.name ?? '', app.id ?? ''].join(' ').toLowerCase();
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

class DeviceAppsStore extends ChangeNotifier
    with IsDisposedMixin, SettingsStoreMixin {
  /// Id length to avoid filename conflict on extract Apk
  static const int kIdLength = 5;

  /// Max tries count to export Apk
  static const int kMaxTriesCount = 10;

  /// List of all device applications
  /// - Include system apps
  /// - Include app icons
  List<PackageInfo> get apps {
    final bool displaySystemApps = settingsStore
        .getBoolPreference(SettingsBoolPreference.displaySystemApps);

    return List<PackageInfo>.unmodifiable(
      _apps.values
          .where(
            (PackageInfo package) =>
                package.isSystemPackage == displaySystemApps,
          )
          .toList()
        ..sort(
          (PackageInfo a, PackageInfo b) =>
              a.name!.toLowerCase().compareTo(b.name!.toLowerCase()),
        ),
    );
  }

  final Map<String, PackageInfo> _apps = <String, PackageInfo>{};

  /// List of all selected applications
  Set<PackageInfo> get selected => Set<PackageInfo>.unmodifiable(
        _selected
            .map((String packageId) => _apps[packageId])
            .where((PackageInfo? package) => package != null)
            .cast<PackageInfo>()
            .toSet(),
      );

  /// List of all selected applications
  final Set<String> _selected = <String>{};

  /// Whether loading device applications or not
  bool isLoading = false;
  int? totalPackagesCount;
  int? get loadedPackagesCount => isLoading ? _apps.length : totalPackagesCount;
  bool get fullyLoaded =>
      !isLoading && loadedPackagesCount == totalPackagesCount;

  void Function(void Function()) throttle = throttleIt500ms();

  Stream<PackageEvent>? _onAppChange;
  StreamSubscription<PackageEvent>? _onAppChangeListener;

  @override
  void dispose() {
    _disposeSettingsStoreListener();
    _disposeAppChangeListener();
    _disposeAppStreamListener();
    super.dispose();
  }

  void _disposeAppStreamListener() {
    _appsStreamSubscription?.cancel();
    _appsStreamSubscription = null;
  }

  void _disposeAppChangeListener() {
    _onAppChangeListener?.cancel();
    _onAppChangeListener = null;
  }

  void _setupInstallAndUninstallListener() {
    if (_onAppChange != null || _onAppChangeListener != null) {
      return;
    }

    _onAppChange = DevicePackages.listenToPackageEvents();
    _onAppChangeListener = _onAppChange!.listen(
      (PackageEvent event) async {
        switch (event.action) {
          case PackageAction.install:
            _apps[event.packageId] = await DevicePackages.getPackage(
              event.packageId,
              includeIcon: true,
            );

            notifyListeners();

            break;
          case PackageAction.update:
            _apps[event.packageId] = await DevicePackages.getPackage(
              event.packageId,
              includeIcon: true,
            );

            notifyListeners();

            break;
          case PackageAction.uninstall:
            _apps.remove(event.packageId);

            notifyListeners();

            break;
        }
      },
      cancelOnError: true,
      onError: (_) => _disposeAppChangeListener(),
      onDone: () => _disposeAppChangeListener(),
    );
  }

  StreamSubscription<PackageInfo>? _appsStreamSubscription;

  void _setupSettingsStoreListener() {
    settingsStore.addListener(notifyListeners);
  }

  void _disposeSettingsStoreListener() {
    settingsStore.removeListener(notifyListeners);
  }

  /// Load all device packages
  ///
  /// You need call this method before any action
  Future<void> loadPackages() async {
    _setupSettingsStoreListener();
    _setupInstallAndUninstallListener();

    isLoading = true;

    notifyListeners();

    totalPackagesCount = await DevicePackages.getInstalledPackageCount();

    final Stream<PackageInfo> appsStream =
        DevicePackages.getInstalledPackagesAsStream(
      includeIcon: true,
      includeSystemPackages: true,
      onlyOpenablePackages: true,
    );

    _appsStreamSubscription = appsStream.listen(
      (PackageInfo package) {
        _apps[package.id!] = package;

        throttle(() {
          notifyListeners();
        });
      },
      cancelOnError: true,
      onError: (_) => _disposeAppStreamListener(),
      onDone: () {
        isLoading = false;
        notifyListeners();
        _disposeAppStreamListener();
      },
    );
  }

  /// Mark all apps as unselected
  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  void restoreToDefault() {
    clearSelection();
    disableSearch();
    notifyListeners();
  }

  /// Packages to be rendered on the screen
  List<PackageInfo> get displayableApps => _searchText != null
      ? results.map((ApplicationSearchResult e) => e.app).toList()
      : apps;

  /// Return [true] if all [displayableApps] are selected
  bool get isAllSelected => displayableApps.length == selected.length;

  /// Add [package] to the [selected] Set
  void toggleSelect(PackageInfo package) {
    if (_selected.contains(package.id)) {
      _selected.remove(package.id);
    } else {
      _selected.add(package.id!);
    }

    notifyListeners();
  }

  static const String kApkMimeType = 'application/vnd.android.package-archive';

  /// Extract Apk of a [package]
  Future<ApkExtraction> extractApk(PackageInfo package, {Uri? folder}) async {
    final File apkFile = File(package.installerPath!);
    final String id = await nanoid(kIdLength);

    if (!apkFile.existsSync()) {
      return ApkExtraction(apkFile, Result.notFound);
    }

    final String apkFilename = '${package.name}_${package.id}_$id';

    if (folder == null) {
      await _settingsStore.requestExportLocationIfNotSet();
    }

    final Uri? parentFolder =
        folder ?? await _settingsStore.getAndSetExportLocationIfItExists();

    if (parentFolder != null) {
      final DocumentFile? createdFile = await createFile(
        parentFolder,
        mimeType: kApkMimeType,
        displayName: apkFilename,
        bytes: await apkFile.readAsBytes(),
      );

      if (createdFile != null) {
        if (createdFile.name != null) {
          // It is better to save a local copy of the apk file icon.
          // Because Android does not have an way to load arbitrary apk file icon from URI, only Files.
          // https://stackoverflow.com/questions/58026104/get-the-real-path-of-apk-file-from-uri-shared-from-other-application#comment133215619_58026104.
          // So we would be required to copy the apk uri to a local file, which translates to very poor performance if the apk is too big.
          // it is far more performant to just load a simple icon from a file.
          // Note that this effort is to keep the app far away from MANAGE_EXTERNAL_STORAGE permission
          // and keep it valid for PlayStore.
          await createFile(
            parentFolder,
            mimeType: 'application/octet-stream',
            displayName: '${createdFile.name!}_icon',
            bytes: package.icon,
          );
        }

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
    final List<ApkExtraction> extractions = <ApkExtraction>[];

    final Uri? folder = await requestExportLocation();

    if (folder != null) {
      for (final PackageInfo selected in selected) {
        extractions.add(await extractApk(selected, folder: folder));
      }

      return MultipleApkExtraction(extractions);
    } else {
      return const MultipleApkExtraction(<ApkExtraction>[]);
    }
  }

  /// Verify if a given [package] is selected
  bool isSelected(PackageInfo package) => _selected.contains(package.id);

  void disableSearch() {
    _searchText = null;
    notifyListeners();
  }

  /// Select all [displayableApps], otherwise mark all as unselected
  void toggleSelectAll() {
    if (isAllSelected) {
      _selected.clear();
    } else {
      _selected
        ..clear()
        ..addAll(displayableApps.map((PackageInfo e) => e.id!));
    }

    notifyListeners();
  }

  bool get isSearchMode => _searchText != null;

  List<ApplicationSearchResult> get results {
    if (_searchText == null) return <ApplicationSearchResult>[];

    final List<ApplicationSearchResult> filtered = apps
        .map(
          (PackageInfo app) =>
              ApplicationSearchResult(app: app, text: _searchText!),
        )
        .where((ApplicationSearchResult result) => result.hasMatch())
        .toList()
      ..sort(
        (ApplicationSearchResult a, ApplicationSearchResult z) =>
            z.compareTo(a),
      );

    return filtered;
  }

  String? _searchText;

  final void Function(void Function() p1) debounceSearch = debounceIt50ms();

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
