import 'package:flutter/material.dart';

import '../stores/background_task_store.dart';
import '../stores/indexed_collection_store.dart';
import '../widgets/toast.dart';
import 'app_localization_strings.dart';

extension ContextTryInstallApk on BuildContext {
  Future<void> tryInstallPackage({
    required BackgroundTaskStore backgroundTaskStore,
    required String taskId,
    Uri? packageUri,
  }) async {
    if (packageUri == null) {
      return showToast(this, strings.invalidPackageUri);
    }

    final PackageInstallationIntentResult result =
        await backgroundTaskStore.installPackage(
      installationId: taskId,
      uri: packageUri,
    );

    if (!result.ok) {
      if (mounted) {
        showToast(
          this,
          strings.invalidApkItWasProbablyDeleted,
        );
      }
    }
  }
}
