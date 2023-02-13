import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/saf.dart';

import '../setup.dart';
import '../utils/apply_if_not_null.dart';

mixin SettingsStoreMixin<T extends StatefulWidget> on State<T> {
  SettingsStore? _settingsStore;
  SettingsStore get settingsStore => _settingsStore ??= getIt<SettingsStore>();

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _settingsStore = null; // Refresh store instance when updating the widget
  }
}

class SettingsStore extends ChangeNotifier {
  /// Use it for display only features, do not rely on it to create files
  /// because it can no longer exists if the user deleted.
  ///
  /// If you need it to make IO operations call [getExportLocationIfItExists] instead.
  Uri? exportLocation;

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

  Future<void> reset() async => _setExportLocation(null);
}
