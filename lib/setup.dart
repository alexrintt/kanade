import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'stores/apk_list_store.dart';
import 'stores/bottom_navigation.dart';
import 'stores/contextual_menu.dart';
import 'stores/device_apps.dart';
import 'stores/key_value_storage.dart';
import 'stores/localization_store.dart';
import 'stores/settings.dart';
import 'stores/theme.dart';

final GetIt getIt = GetIt.instance;
late PackageInfo packageInfo;

Future<void> setup() async {
  WidgetsFlutterBinding.ensureInitialized();

  packageInfo = await PackageInfo.fromPlatform();

  getIt
    ..registerLazySingleton<DeviceAppsStore>(() => DeviceAppsStore())
    ..registerLazySingleton<ContextualMenuStore>(() => ContextualMenuStore())
    ..registerLazySingleton<SettingsStore>(() => SettingsStore())
    ..registerLazySingleton<KeyValueStorage<String, String?>>(
      () => SharedPreferencesStorage(),
    )
    ..registerLazySingleton<ThemeStore>(() => ThemeStore())
    ..registerLazySingleton<LocalizationStore>(() => LocalizationStore())
    ..registerLazySingleton<BottomNavigationStore>(
      () => BottomNavigationStore(),
    )
    ..registerLazySingleton<ApkListStore>(() => ApkListStore()..start());
}

Future<void> init() async {
  await getIt<KeyValueStorage<String, String?>>().setup();
  await getIt<SettingsStore>().load();
  await getIt<ThemeStore>().load();
  await getIt<LocalizationStore>().load();
}
