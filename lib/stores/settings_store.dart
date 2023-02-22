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
  /// If you need it to make IO operations call [getExportLocationIfItExists] instead.
  Uri? exportLocation;

  final Map<SettingsBoolPreference, bool> _boolPreferences =
      <SettingsBoolPreference, bool>{};

  late SharedPreferences prefs;

  static const String kExportLocation = 'exportLocation';

  Future<Uri?> getAndSetExportLocationIfItExists() async {
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

    if (savedLocation == null) {
      await reset();
    } else {
      await _setExportLocation(savedLocation);
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

  Future<void> requestExportLocationIfNotSet() async {
    final Uri? exportLocation = await getAndSetExportLocationIfItExists();

    if (exportLocation == null) {
      return requestExportLocation();
    }
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

enum SettingsBoolPreference {
  displaySystemApps(defaultValue: false),
  displayAppIcons(defaultValue: true);

  const SettingsBoolPreference({required this.defaultValue});

  String getNameString(AppLocalizations localizations) {
    switch (this) {
      case SettingsBoolPreference.displaySystemApps:
        return 'Show system apps';
      case SettingsBoolPreference.displayAppIcons:
        return 'Show app icons';
    }
  }

  String getDescriptionString(AppLocalizations localizations) {
    switch (this) {
      case SettingsBoolPreference.displaySystemApps:
        return 'Whether or not the home app list should include system apps.';
      case SettingsBoolPreference.displayAppIcons:
        return 'If enabled the home app list will display app icons.';
    }
  }

  final bool defaultValue;

  String get storageKey => 'bool__preference__unique__key__${toString()}';
}
