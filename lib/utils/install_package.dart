import 'dart:io';

import 'package:device_packages/device_packages.dart';

Future<void> installPackage({File? file, Uri? uri, String? path}) async {
  assert(file != null || uri != null || path != null);

  await DevicePackages.installPackage(
    installerUri: uri,
    installerFile: file,
    installerPath: path,
  );
}
