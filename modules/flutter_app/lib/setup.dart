import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:workmanager/workmanager.dart';

import 'setup.config.dart';

final GetIt getIt = GetIt.instance;
late PackageInfo packageInfo;

const pragma vmEntryPoint = pragma('vm:entry-point');

// ExtractApkBackgroundTask createExtractApkBackgroundTask(String packageId) {}

@InjectableInit()
Future<void> configureDependencies() => getIt.init();

// Mandatory if the App is obfuscated or using Flutter 3.1+
@vmEntryPoint
void callbackDispatcher() {
  Workmanager()
      .executeTask((String task, Map<String, dynamic>? inputData) async {
    final requestType = inputData?['requestType'];

    return false;
  });
}

@vmEntryPoint
Future<void> setupDependencies() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  await Workmanager().initialize(
    callbackDispatcher, // The top level function, aka callbackDispatcher
    isInDebugMode: kDebugMode,
  );

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );

  packageInfo = await PackageInfo.fromPlatform();
}
