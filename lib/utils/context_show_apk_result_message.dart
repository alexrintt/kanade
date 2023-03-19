import 'package:flutter/material.dart';

import '../stores/device_apps_store.dart';
import '../widgets/toast.dart';
import 'app_localization_strings.dart';

extension ContextShowApkResultMessage on BuildContext {
  void showApkResultMessage(Result result) {
    switch (result) {
      case Result.permissionDenied:
        showToast(this, strings.permissionDenied);
        break;
      case Result.permissionRestricted:
        showToast(this, strings.permissionRestrictedByAndroid);
        break;
      case Result.notAllowed:
        showToast(
          this,
          strings.operationNotAllowedMayBeProtectedPackage,
        );
        break;
      case Result.notFound:
        showToast(
          this,
          // TODO: Missing translation.
          'Could not extract, this apk was probably uninstalled because we did not found it is apk file',
        );
        break;
      case Result.queued:
        // The bottom navigation bar actually changes its badge indicator,
        // so we don't need to do anything here to indicate the apk is being extracted.
        showToast(this, "Queued! Check the 'Apks' tab");
        break;
    }
  }
}
