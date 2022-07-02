import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:kanade/constants/app_colors.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';
import 'package:kanade/stores/settings.dart';

final getIt = GetIt.instance;

Future<void> setup() async {
  getIt.registerLazySingleton<DeviceAppsStore>(() => DeviceAppsStore());
  getIt.registerLazySingleton<ContextualMenuStore>(() => ContextualMenuStore());
  getIt.registerLazySingleton<SettingsStore>(() => SettingsStore());
}

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Set System Status Bar Color
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: appColors.appBarTheme.backgroundColor,
      statusBarIconBrightness: appColors.brightness,
    ),
  );

  await getIt<SettingsStore>().load();
}
