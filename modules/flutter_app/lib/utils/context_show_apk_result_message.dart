import 'package:flutter/material.dart';

import '../stores/device_apps_store.dart';
import '../widgets/toast.dart';
import 'app_localization_strings.dart';

extension ContextShowApkResultMessage on BuildContext {
  void showApkResultMessage(SingleExtractionResult result) {
    switch (result) {
      case SingleExtractionResult.permissionDenied:
        showToast(this, strings.permissionDenied);
      case SingleExtractionResult.permissionRestricted:
        showToast(this, strings.permissionRestrictedByAndroid);
      case SingleExtractionResult.notAllowed:
        showToast(
          this,
          strings.operationNotAllowedMayBeProtectedPackage,
        );
      case SingleExtractionResult.notFound:
        showToast(
          this,
          strings.couldNotExtractWithExplanation,
        );
      case SingleExtractionResult.queued:
        // The bottom navigation bar actually changes its badge indicator,
        // so we don't need to do anything here to indicate the apk is being extracted.
        showToast(this, strings.successQueued);
    }
  }
}
