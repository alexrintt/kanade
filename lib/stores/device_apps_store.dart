import 'dart:async';
import 'dart:io';

import 'package:device_packages/device_packages.dart';

import '../setup.dart';
import '../utils/is_disposed_mixin.dart';
import '../utils/throttle.dart';
import 'background_task_store.dart';
import 'indexed_collection_store.dart';
import 'settings_store.dart';

mixin DeviceAppsStoreMixin {
  DeviceAppsStore? _store;
  DeviceAppsStore get store => _store ??= getIt<DeviceAppsStore>();
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
  queued,
  permissionDenied,
  permissionRestricted,
  notAllowed,
  notFound;

  /// Happy end, for now, a request was made to start the job in background.
  bool get success => this == queued;

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

class DeviceAppsStore extends IndexedCollectionStore<PackageInfo>
    with
        IsDisposedMixin,
        SettingsStoreMixin,
        SelectableStoreMixin<PackageInfo>,
        SearchableStoreMixin<PackageInfo>,
        LoadingStoreMixin<PackageInfo>,
        ProgressIndicatorMixin {
  bool _filterAppsByPreferences(PackageInfo package) {
    final bool displaySystemApps = settingsStore
        .getBoolPreference(SettingsBoolPreference.displaySystemApps);

    final bool displayBuiltInApps = settingsStore
        .getBoolPreference(SettingsBoolPreference.displayBuiltInApps);

    final bool displayUserInstalledApps = settingsStore
        .getBoolPreference(SettingsBoolPreference.displayUserInstalledApps);

    if (displaySystemApps) {
      if (package.isSystemPackage ?? false) {
        return true;
      }
    }

    if (displayBuiltInApps) {
      if (package.isSystemPackage ?? false) {
        if (package.isOpenable ?? false) {
          return true;
        }
      }
    }

    if (displayUserInstalledApps) {
      if (!(package.isSystemPackage ?? true)) {
        if (package.isOpenable ?? false) {
          return true;
        }
      }
    }

    return false;
  }

  List<PackageInfo> get apps => collection;

  int _byPackageNameAsc(PackageInfo a, PackageInfo b) =>
      a.name!.toLowerCase().compareTo(b.name!.toLowerCase());

  @override
  List<PackageInfo> get collection {
    return List<PackageInfo>.unmodifiable(
      super.collection.where(_filterAppsByPreferences).toList()
        ..sort(_byPackageNameAsc),
    );
  }

  final Map<String, PackageInfo> _apps = <String, PackageInfo>{};

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

            defineTotalItemsCount(totalCount ?? 0 + 1);

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

            defineTotalItemsCount(totalCount ?? 0 - 1);

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

    defineTotalItemsCount(
      await DevicePackages.getInstalledPackageCount(
        includeSystemPackages: true,
      ),
    );

    final Stream<PackageInfo> appsStream =
        DevicePackages.getInstalledPackagesAsStream(
      includeIcon: true,
      includeSystemPackages: true,
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

  void restoreToDefault() {
    clearSelection();
    disableSearch();
    notifyListeners();
  }

  @override
  List<String> createSearchableStringsOf(PackageInfo item) {
    return <String>[item.name ?? '', item.id ?? ''];
  }

  BackgroundTaskStore get _backgroundTaskStore => getIt<BackgroundTaskStore>();

  Future<ApkExtraction> extractApk(PackageInfo package, {Uri? folder}) async {
    final File apkFile = File(package.installerPath!);

    if (!apkFile.existsSync()) {
      return ApkExtraction(apkFile, Result.notFound);
    }

    if (folder == null) {
      await _settingsStore.requestExportLocationIfNotSet();
    }

    final Uri? parentFolder =
        folder ?? await _settingsStore.getAndSetExportLocationIfItExists();

    if (parentFolder != null) {
      unawaited(
        _backgroundTaskStore.queue(
          ExtractApkBackgroundTask.create(
            packageId: package.id!,
            parentUri: parentFolder,
            createdAt: DateTime.now(),
          ),
        ),
      );
      return ApkExtraction(apkFile, Result.queued);
    }

    return ApkExtraction(apkFile, Result.permissionDenied);
  }

  Future<Uri?> requestExportLocation() async {
    return _settingsStore.requestExportLocationIfNotSet();
  }

  SettingsStore get _settingsStore => getIt<SettingsStore>();

  @override
  bool canBeSelected(PackageInfo package) {
    return apps.map((PackageInfo e) => e.id!).toSet().contains(package.id);
  }

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

  @override
  Map<String, PackageInfo> get collectionIndexedById => _apps;

  @override
  String getItemId(PackageInfo item) {
    return item.id!;
  }
}
