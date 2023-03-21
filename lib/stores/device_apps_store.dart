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

class SingleExtraction {
  const SingleExtraction(this.package, this.result);
  const SingleExtraction.notFound(this.package)
      : result = SingleExtractionResult.notFound;

  final PackageInfo? package;
  final SingleExtractionResult result;
}

enum SingleExtractionResult {
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

enum MultipleExtractionResult {
  allExtracted,
  allFailed,
  someFailed,
  permissionDenied;

  /// Happy end, all apk's extracted successfully
  bool get success => this == allExtracted;

  /// All apk's extractions failed due one or more reasons
  bool get failed => this == allFailed;

  /// Some apk's failed but others was successfully extracted
  bool get someMayFailed => this == someFailed;

  /// User denied permission
  bool get permissionWasDenied => this == permissionDenied;
}

class MultipleExtraction {
  const MultipleExtraction(this.extractions);

  final List<SingleExtraction> extractions;

  /// Overall result based on [extractions] results
  MultipleExtractionResult get result {
    final bool permissionWasDenied = extractions.any(
      (SingleExtraction extraction) => extraction.result.permissionWasDenied,
    );

    if (permissionWasDenied) return MultipleExtractionResult.permissionDenied;

    final int successfulExtractionsCount = extractions
        .where((SingleExtraction extraction) => extraction.result.success)
        .length;

    if (successfulExtractionsCount == 0) {
      return MultipleExtractionResult.allFailed;
    }

    if (successfulExtractionsCount == extractions.length) {
      return MultipleExtractionResult.allExtracted;
    }

    return MultipleExtractionResult.someFailed;
  }
}

class DeviceAppsStore extends IndexedCollectionStore<PackageInfo>
    with
        IsDisposedMixin,
        SettingsStoreMixin,
        SelectableStoreMixin<PackageInfo>,
        SearchableStoreMixin<PackageInfo>,
        LoadingStoreMixin<PackageInfo>,
        ProgressIndicatorMixin {
  bool get _displaySystemApps =>
      settingsStore.getBoolPreference(SettingsBoolPreference.displaySystemApps);
  bool get _displayBuiltInApps => settingsStore
      .getBoolPreference(SettingsBoolPreference.displayBuiltInApps);
  bool get _displayUserInstalledApps => settingsStore
      .getBoolPreference(SettingsBoolPreference.displayUserInstalledApps);

  bool _filterAppsByPreferences(
    PackageInfo package, {
    required bool displaySystemApps,
    required bool displayBuiltInApps,
    required bool displayUserInstalledApps,
  }) {
    if (displaySystemApps) {
      if (package.isSystemPackage == true) {
        return true;
      }
    }

    if (displayBuiltInApps) {
      if (package.isSystemPackage == true) {
        if (package.isOpenable == true) {
          return true;
        }
      }
    }

    if (displayUserInstalledApps) {
      if (package.isSystemPackage == false) {
        return true;
      }
    }

    return false;
  }

  List<PackageInfo> get apps => collection;

  int _byPackageNameAsc(PackageInfo a, PackageInfo b) =>
      a.name!.toLowerCase().compareTo(b.name!.toLowerCase());

  List<PackageInfo> _filterPackagesBy({
    required bool displaySystemApps,
    required bool displayBuiltInApps,
    required bool displayUserInstalledApps,
  }) =>
      super
          .collection
          .where(
            (PackageInfo e) => _filterAppsByPreferences(
              e,
              displayBuiltInApps: displayBuiltInApps,
              displaySystemApps: displaySystemApps,
              displayUserInstalledApps: displayUserInstalledApps,
            ),
          )
          .toList();

  @override
  List<PackageInfo> get collection {
    return List<PackageInfo>.unmodifiable(
      _filterPackagesBy(
        displayBuiltInApps: _displayBuiltInApps,
        displaySystemApps: _displaySystemApps,
        displayUserInstalledApps: _displayUserInstalledApps,
      )..sort(_byPackageNameAsc),
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
    settingsStore.addListener(() {
      for (final PackageInfo element in selected) {
        // Try to select all selected items again,
        // if they are not allowed anymore, they will be unselected.
        select(item: element, notify: false);
      }

      notifyListeners();
    });
  }

  void _disposeSettingsStoreListener() {
    settingsStore.removeListener(notifyListeners);
  }

  bool hasRiskOfUnintentionalUnselect({
    required bool displaySystemApps,
    required bool displayBuiltInApps,
    required bool displayUserInstalledApps,
  }) {
    final List<PackageInfo> preview = _filterPackagesBy(
      displaySystemApps: displaySystemApps,
      displayBuiltInApps: displayBuiltInApps,
      displayUserInstalledApps: displayUserInstalledApps,
    );

    // If any selected package is not contained by the next collection filter, then
    // the user may will lose some selected items. This is painful if you are selecting hundred of items
    // by hand and unintentionally select a filter that erases your selection. So in this case we must confirm with a dialog.
    //
    // This is really rare to happen though.
    return selected.any((PackageInfo package) {
      return !preview.contains(package);
    });
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
    unselectAll();
    disableSearch();
    notifyListeners();
  }

  @override
  List<String> createSearchableStringsOf(PackageInfo item) {
    return <String>[item.name ?? '', item.id ?? ''];
  }

  BackgroundTaskStore get _backgroundTaskStore => getIt<BackgroundTaskStore>();

  Future<void> uninstallApp(String packageId) async {
    await DevicePackages.uninstallPackage(packageId);
  }

  Future<List<SingleExtraction>> _extractApks({
    List<PackageInfo>? packages,
    List<String>? packageIds,
    Uri? folder,
  }) async {
    assert(packages != null || packageIds != null);

    late Map<String, PackageInfo?> targets;
    final List<ExtractApkBackgroundTask> tasks = <ExtractApkBackgroundTask>[];

    if (packages != null) {
      targets = <String, PackageInfo?>{
        for (final PackageInfo package in packages)
          if (package.id != null) package.id!: package,
      };
    } else {
      targets = <String, PackageInfo?>{
        for (final String packageId in packageIds!)
          packageId: collectionIndexedById[packageId],
      };
    }

    final List<SingleExtraction> results = <SingleExtraction>[];

    bool denied = false;

    for (final MapEntry<String, PackageInfo?> entry in targets.entries) {
      final PackageInfo? package = entry.value;

      if (package == null) {
        results.add(SingleExtraction.notFound(package));
        continue;
      }

      final File apkFile = File(package.installerPath!);

      if (denied) {
        results.add(
          SingleExtraction(package, SingleExtractionResult.permissionDenied),
        );
        continue;
      }

      if (!apkFile.existsSync()) {
        results.add(SingleExtraction(package, SingleExtractionResult.notFound));
        continue;
      }

      if (folder == null) {
        await _settingsStore.requestExportLocationIfNotSet();
      }

      final Uri? parentFolder =
          folder ?? await _settingsStore.getAndSetExportLocationIfItExists();

      if (parentFolder != null) {
        tasks.add(
          ExtractApkBackgroundTask.create(
            packageId: package.id!,
            parentUri: parentFolder,
            createdAt: DateTime.now(),
          ),
        );

        results.add(SingleExtraction(package, SingleExtractionResult.queued));

        continue;
      }

      results.add(
        SingleExtraction(package, SingleExtractionResult.permissionDenied),
      );

      denied = true;
    }

    // Queue all at once.
    if (tasks.isNotEmpty) unawaited(_backgroundTaskStore.queueMany(tasks));

    return results;
  }

  Future<Uri?> requestExportLocationIfNotSet() async {
    return _settingsStore.requestExportLocationIfNotSet();
  }

  SettingsStore get _settingsStore => getIt<SettingsStore>();

  @override
  bool canBeSelected(PackageInfo package) {
    return apps.map((PackageInfo e) => e.id!).toSet().contains(package.id);
  }

  /// Extract Apk of all [selected] apps
  Future<MultipleExtraction> extractSelectedApks() async {
    return MultipleExtraction(await _extractApks(packages: selected.toList()));
  }

  Future<SingleExtraction> extractApk({
    PackageInfo? package,
    String? packageId,
  }) async {
    assert(package != null || packageId != null);
    final PackageInfo? target = package ?? collectionIndexedById[packageId];

    if (target == null) {
      return SingleExtraction.notFound(package);
    }

    final Uri? folder = await requestExportLocationIfNotSet();

    if (folder != null) {
      final List<SingleExtraction> extractions =
          await _extractApks(packages: <PackageInfo>[target], folder: folder);

      if (extractions.isEmpty) {
        return SingleExtraction.notFound(package);
      }

      return extractions.first;
    } else {
      return SingleExtraction(package, SingleExtractionResult.permissionDenied);
    }
  }

  @override
  Map<String, PackageInfo> get collectionIndexedById => _apps;

  @override
  String getItemId(PackageInfo item) {
    return item.id!;
  }
}
