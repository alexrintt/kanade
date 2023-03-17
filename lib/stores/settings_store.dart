import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/saf.dart';

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

  bool get isCompactMode =>
      getBoolPreference(SettingsBoolPreference.compactMode);

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
  displayAppIcons(
    defaultValue: true,
    category: SettingsBoolPreferenceCategory.appearance,
  ),
  transparentBottomNavigationBar(
    defaultValue: false,
    category: SettingsBoolPreferenceCategory.appearance,
  ),
  compactMode(
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

  String getNameString(AppLocalizations localizations) {
    switch (this) {
      case SettingsBoolPreference.hideAppBarOnScroll:
        return 'Hide app bar on scroll';
      case SettingsBoolPreference.confirmIrreversibleActions:
        return 'Ask for confirmation';
      case SettingsBoolPreference.compactMode:
        return 'Compact mode';
      case SettingsBoolPreference.displaySystemApps:
        return 'Show system apps';
      case SettingsBoolPreference.displayAppIcons:
        return 'Show app icons';
      case SettingsBoolPreference.displayBuiltInApps:
        return 'Show built-in apps';
      case SettingsBoolPreference.displayUserInstalledApps:
        return 'Show user installed apps';
      case SettingsBoolPreference.transparentBottomNavigationBar:
        return 'Transparent bottom navigation bar';
    }
  }

  String getDescriptionString(AppLocalizations localizations) {
    switch (this) {
      case SettingsBoolPreference.confirmIrreversibleActions:
        return 'Ask for confirmation whenever the user tries to do any irreversible action like deleting a file.';
      case SettingsBoolPreference.hideAppBarOnScroll:
        return 'If enabled, the app bar will automatically hide when scroll down.';
      case SettingsBoolPreference.compactMode:
        return 'Show the home app list in compact mode, less space and more content.';
      case SettingsBoolPreference.displaySystemApps:
        return 'If enabled the home list will include system apps, they may not be launchable.';
      case SettingsBoolPreference.displayAppIcons:
        return 'If enabled the home app list will show the app icons.';
      case SettingsBoolPreference.displayBuiltInApps:
        return 'If enabled the home list will include built-in apps, they are like system apps but openable.';
      case SettingsBoolPreference.displayUserInstalledApps:
        return 'If enabled the home list will include apps installed by you.';
      case SettingsBoolPreference.transparentBottomNavigationBar:
        return 'Apply a blur transparent effect to the home navigation bar.';
    }
  }

  final bool defaultValue;

  String get storageKey => 'bool__preference__unique__key__${toString()}';
}
