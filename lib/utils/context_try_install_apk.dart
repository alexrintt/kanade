import 'package:flutter/material.dart';

import '../stores/background_task_store.dart';
import '../stores/indexed_collection_store.dart';
import '../widgets/toast.dart';

extension ContextTryInstallApk on BuildContext {
  Future<void> tryInstallPackage({
    required BackgroundTaskStore backgroundTaskStore,
    required String taskId,
    Uri? packageUri,
  }) async {
    if (packageUri == null) {
      return showToast(this, 'Invalid package Uri, got null');
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
          'Invalid apk, it is was probably deleted.',
        );
      }
    }
  }
}
