import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';
import 'package:kanade/stores/persistent_hash_map.dart';
import 'package:kanade/stores/settings.dart';
import 'package:kanade/stores/theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

final getIt = GetIt.instance;
late PackageInfo packageInfo;

Future<void> setup() async {
  WidgetsFlutterBinding.ensureInitialized();

  packageInfo = await PackageInfo.fromPlatform();

  getIt
    ..registerLazySingleton<DeviceAppsStore>(() => DeviceAppsStore())
    ..registerLazySingleton<ContextualMenuStore>(() => ContextualMenuStore())
    ..registerLazySingleton<SettingsStore>(() => SettingsStore())
    ..registerLazySingleton<KeyValueStorage<String, String?>>(
        () => SharedPreferencesStorage())
    ..registerLazySingleton<ThemeStore>(() => ThemeStore());
}

Future<void> init() async {
  await getIt<KeyValueStorage<String, String?>>().setup();
  await getIt<SettingsStore>().load();
  await getIt<ThemeStore>().load();
}
