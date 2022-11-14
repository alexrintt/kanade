import 'package:flutter/cupertino.dart';
import 'package:kanade/utils/apply_if_not_null.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/saf.dart';

class SettingsStore extends ChangeNotifier {
  /// Use it for display only features, do not rely on it to create files
  /// because it can no longer exists if the user deleted.
  ///
  /// If you need it to make IO operations call [getExportLocationIfItExists] instead.
  Uri? exportLocation;

  late SharedPreferences prefs;

  static const kExportLocation = 'exportLocation';

  Future<Uri?> getAndSetExportLocationIfItExists() async {
    final savedLocationString = prefs.getString(kExportLocation);
    var savedLocation =
        savedLocationString?.apply((location) => Uri.parse(location));

    if (savedLocation != null) {
      final savedLocationExists = await exists(savedLocation) ?? false;

      if (!savedLocationExists) {
        savedLocation = null;
      }
    }

    if (savedLocation == null) {
      reset();
    } else {
      await setExportLocation(savedLocation);
    }

    return savedLocation;
  }

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();

    await getAndSetExportLocationIfItExists();
  }

  Future<void> setExportLocation(Uri location) async {
    exportLocation = location;

    await prefs.setString(kExportLocation, '$location');

    notifyListeners();
  }

  Future<void> requestExportLocation() async {
    final uri = await openDocumentTree(initialUri: exportLocation);

    if (uri != null) {
      await setExportLocation(uri);
    } else {
      // Update the folder if it no longer exists.
      await getAndSetExportLocationIfItExists();
    }
  }

  Future<void> requestExportLocationIfNotSet() async {
    final exportLocation = await getAndSetExportLocationIfItExists();

    if (exportLocation == null) {
      return requestExportLocation();
    }
  }

  Future<void> reset() async {
    exportLocation = null;
    await prefs.remove(kExportLocation);
    notifyListeners();
  }
}
