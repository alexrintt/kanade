import 'package:flutter/cupertino.dart';
import 'package:kanade/utils/apply_if_not_null.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/saf.dart';

class SettingsStore extends ChangeNotifier {
  Uri? exportLocation;
  late SharedPreferences prefs;

  static const kExportLocation = 'exportLocation';

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();

    final location = prefs.getString(kExportLocation);

    exportLocation = location?.apply((location) => Uri.parse(location));
  }

  Future<void> setExportLocation(Uri location) async {
    exportLocation = location;

    await prefs.setString(kExportLocation, '$location');

    notifyListeners();
  }

  Future<void> requestExportLocation() async {
    final uri = await openDocumentTree(initialUri: exportLocation);

    if (uri != null) await setExportLocation(uri);
  }

  Future<void> requestExportLocationIfNotSet() async {
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
