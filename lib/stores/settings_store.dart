import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/shared_storage.dart';

import '../setup.dart';
import '../utils/apply_if_not_null.dart';

mixin SettingsStoreMixin {
  SettingsStore? _settingsStore;
  SettingsStore get settingsStore => _settingsStore ??= getIt<SettingsStore>();
}

class SettingsStore extends ChangeNotifier {
  /// Use it for display only features, do not rely on it to create files
  /// because it can no longer exists if the user deleted.
  ///
  /// If you need it to make IO operations call [getAndSetExportLocationIfItExists] instead.
  Uri? exportLocation;

  final Map<SettingsBoolPreference, bool> _boolPreferences =
      <SettingsBoolPreference, bool>{};

  late SharedPreferences prefs;

  static const String kExportLocation = 'exportLocation';

  bool get shouldConfirmIrreversibleActions =>
      getBoolPreference(SettingsBoolPreference.confirmIrreversibleActions);

  bool get transparentNavigationBar =>
      getBoolPreference(SettingsBoolPreference.transparentNavigationBar);

  bool get shouldExtractWithSingleClick =>
      getBoolPreference(SettingsBoolPreference.extractWithSingleClick);

  Future<Uri?> getAndSetExportLocationIfItExists() async {
    final Uri? currentLocation = exportLocation;

    Uri? savedLocation = prefs
        .getString(kExportLocation)
        .apply((String location) => Uri.parse(location));

    // Ensure the saved location still exists.
    // e.g the user deleted the folder through a third-party app.
    if (savedLocation != null) {
      final bool savedLocationExists = await exists(savedLocation) ?? false;

      if (!savedLocationExists) {
        savedLocation = null;
      }
    }

    if (savedLocation != currentLocation) {
      if (savedLocation == null) {
        await reset();
      } else {
        await _setExportLocation(savedLocation);
      }
    }

    return savedLocation;
  }

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();

    await getAndSetExportLocationIfItExists();
    await _loadBoolPreferences();
  }

  Future<void> _loadBoolPreferences() async {
    for (final SettingsBoolPreference preference
        in SettingsBoolPreference.values) {
      if (!prefs.containsKey(preference.storageKey)) {
        await prefs.setBool(preference.storageKey, preference.defaultValue);
      }

      _boolPreferences[preference] =
          prefs.getBool(preference.storageKey) ?? preference.defaultValue;
    }
  }

  Future<void> _setExportLocation(Uri? location) async {
    exportLocation = location;

    if (location == null) {
      await prefs.remove(kExportLocation);
    } else {
      await prefs.setString(kExportLocation, '$location');
    }

    notifyListeners();
  }

  Future<void> requestExportLocation() async {
    final Uri? uri = await openDocumentTree(initialUri: exportLocation);

    if (uri != null) {
      await _setExportLocation(uri);
    } else {
      // Update the folder if it no longer exists.
      await getAndSetExportLocationIfItExists();
    }
  }

  Future<Uri?> requestExportLocationIfNotSet() async {
    Uri? location = await getAndSetExportLocationIfItExists();

    if (location == null) {
      await requestExportLocation();
      location = exportLocation;
    }

    return location;
  }

  Future<void> reset() async {
    await _setExportLocation(null);
    await _resetAllBoolPreferences();
  }

  Future<void> _resetAllBoolPreferences() async {
    for (final SettingsBoolPreference preference
        in SettingsBoolPreference.values) {
      await resetBoolPreference(preference);
    }
  }

  Future<void> resetBoolPreference(SettingsBoolPreference preference) {
    return setBoolPreference(preference, value: preference.defaultValue);
  }

  bool getBoolPreference(SettingsBoolPreference preference) {
    return _boolPreferences[preference] ?? preference.defaultValue;
  }

  Future<void> toggleBoolPreference(SettingsBoolPreference preference) {
    return setBoolPreference(preference, value: !getBoolPreference(preference));
  }

  Future<void> setBoolPreference(
    SettingsBoolPreference preference, {
    required bool value,
  }) async {
    await prefs.setBool(preference.storageKey, value);
    _boolPreferences[preference] = value;
    notifyListeners();
  }
}

enum SettingsBoolPreferenceCategory {
  behavior,
  appearance,
}

enum SettingsBoolPreference {
  displaySystemApps(
    defaultValue: false,
    category: SettingsBoolPreferenceCategory.behavior,
  ),
  displayBuiltInApps(
    defaultValue: true,
    category: SettingsBoolPreferenceCategory.behavior,
  ),
  displayUserInstalledApps(
    defaultValue: true,
    category: SettingsBoolPreferenceCategory.behavior,
  ),
  extractWithSingleClick(
    defaultValue: true,
    category: SettingsBoolPreferenceCategory.behavior,
  ),
  transparentNavigationBar(
    defaultValue: false,
    category: SettingsBoolPreferenceCategory.appearance,
  ),
  hideAppBarOnScroll(
    defaultValue: true,
    category: SettingsBoolPreferenceCategory.appearance,
  ),
  confirmIrreversibleActions(
    defaultValue: true,
    category: SettingsBoolPreferenceCategory.behavior,
  );

  const SettingsBoolPreference({
    required this.defaultValue,
    required this.category,
  });

  static List<SettingsBoolPreference> filterBy({
    bool? defaultValue,
    SettingsBoolPreferenceCategory? category,
  }) {
    return values.where(
      (SettingsBoolPreference value) {
        return value.defaultValue == (defaultValue ?? value.defaultValue) &&
            value.category == (category ?? value.category);
      },
    ).toList();
  }

  final SettingsBoolPreferenceCategory category;

  String getNameString(AppLocalizations strings) {
    switch (this) {
      case SettingsBoolPreference.hideAppBarOnScroll:
        return strings.hideAppBarOnScroll;
      case SettingsBoolPreference.extractWithSingleClick:
        return strings.extractWithSingleClick;
      case SettingsBoolPreference.confirmIrreversibleActions:
        return strings.confirmIrreversibleActions;
      case SettingsBoolPreference.displaySystemApps:
        return strings.displaySystemApps;
      case SettingsBoolPreference.displayBuiltInApps:
        return strings.displayBuiltInApps;
      case SettingsBoolPreference.displayUserInstalledApps:
        return strings.displayUserInstalledApps;
      case SettingsBoolPreference.transparentNavigationBar:
        return strings.transparentNavigationBar;
    }
  }

  String getDescriptionString(AppLocalizations strings) {
    switch (this) {
      case SettingsBoolPreference.confirmIrreversibleActions:
        return strings.confirmIrreversibleActionsExplanation;
      case SettingsBoolPreference.hideAppBarOnScroll:
        return strings.hideAppBarOnScrollExplanation;
      case SettingsBoolPreference.displaySystemApps:
        return strings.displaySystemAppsExplanation;
      case SettingsBoolPreference.displayBuiltInApps:
        return strings.displayBuiltInAppsExplanation;
      case SettingsBoolPreference.displayUserInstalledApps:
        return strings.displayUserInstalledAppsExplanation;
      case SettingsBoolPreference.transparentNavigationBar:
        return strings.transparentNavigationBarExplanation;
      case SettingsBoolPreference.extractWithSingleClick:
        return strings.extractWithSingleClickExplanation;
    }
  }

  final bool defaultValue;

  String get storageKey => 'bool__preference__unique__key__${toString()}';
}
