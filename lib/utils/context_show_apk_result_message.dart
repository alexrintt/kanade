import 'package:flutter/material.dart';

import '../stores/device_apps_store.dart';
import '../widgets/toast.dart';
import 'app_localization_strings.dart';

extension ContextShowApkResultMessage on BuildContext {
  void showApkResultMessage(SingleExtractionResult result) {
    switch (result) {
      case SingleExtractionResult.permissionDenied:
        showToast(this, strings.permissionDenied);
        break;
      case SingleExtractionResult.permissionRestricted:
        showToast(this, strings.permissionRestrictedByAndroid);
        break;
      case SingleExtractionResult.notAllowed:
        showToast(
          this,
          strings.operationNotAllowedMayBeProtectedPackage,
        );
        break;
      case SingleExtractionResult.notFound:
        showToast(
          this,
          strings.couldNotExtractWithExplanation,
        );
        break;
      case SingleExtractionResult.queued:
        // The bottom navigation bar actually changes its badge indicator,
        // so we don't need to do anything here to indicate the apk is being extracted.
        showToast(this, strings.successQueued);
        break;
    }
  }
}
