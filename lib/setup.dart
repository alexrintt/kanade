import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'stores/background_task_store.dart';
import 'stores/bottom_navigation_store.dart';
import 'stores/contextual_menu_store.dart';
import 'stores/device_apps_store.dart';
import 'stores/file_list_store.dart';
import 'stores/global_file_change_store.dart';
import 'stores/key_value_storage.dart';
import 'stores/localization_store.dart';
import 'stores/settings_store.dart';
import 'stores/theme_store.dart';

final GetIt getIt = GetIt.instance;
late PackageInfo packageInfo;

Future<void> setup() async {
  WidgetsFlutterBinding.ensureInitialized();

  packageInfo = await PackageInfo.fromPlatform();

  getIt
    ..registerLazySingleton<GlobalFileChangeStore>(
      () => GlobalFileChangeStore(),
    )
    ..registerLazySingleton<DeviceAppsStore>(() => DeviceAppsStore())
    ..registerLazySingleton<SettingsStore>(() => SettingsStore())
    ..registerLazySingleton<KeyValueStorage<String, String?>>(
      () => SharedPreferencesStorage(),
    )
    ..registerLazySingleton<ThemeStore>(() => ThemeStore())
    ..registerLazySingleton<LocalizationStore>(() => LocalizationStore())
    ..registerLazySingleton<BottomNavigationStore>(
      () => BottomNavigationStore(),
    )
    ..registerLazySingleton<BackgroundTaskStore>(() => BackgroundTaskStore())
    ..registerLazySingleton<FileListStore>(() => FileListStore());

  // Most items that are not singleton (probably) need to be
  // used with [Provider] in order to make use of the correct instance (that's why singletons does not need Provider, because
  // there is only one instance throughout the entire app widget tree).
  getIt.registerFactory<ContextualMenuStore>(() => ContextualMenuStore());
}

Future<void> init() async {
  await getIt<GlobalFileChangeStore>().load();
  await getIt<KeyValueStorage<String, String?>>().setup();
  await getIt<SettingsStore>().load();
  await getIt<ThemeStore>().load();
  await getIt<LocalizationStore>().load();
  await getIt<BackgroundTaskStore>().load();
  await getIt<FileListStore>().load();
}
