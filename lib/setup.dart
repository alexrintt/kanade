import 'package:get_it/get_it.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';

final getIt = GetIt.instance;

Future<void> setup() async {
  getIt.registerLazySingleton<DeviceAppsStore>(() => DeviceAppsStore());
  getIt.registerLazySingleton<ContextualMenuStore>(() => ContextualMenuStore());
}
