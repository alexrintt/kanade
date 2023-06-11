import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_storage/shared_storage.dart' as shared_storage;

Future<void> tryShareFile({Uri? uri, String? path, File? file}) async {
  if (path == null && file == null && uri == null) {
    return log('Tried to call [shareFile] with all arguments set to [null].');
  }

  try {
    await shared_storage.shareUriOrFile(
      uri: uri,
      filePath: path,
      file: file,
    );
  } on PlatformException catch (e) {
    // The user clicked twice too fast, which created 2 share requests and the second one failed.
    // Unhandled Exception: PlatformException(Share callback error, prior share-sheet did not call back, did you await it? Maybe use non-result variant, null, null).
    log('Error when calling [shareFile]: $e');
    return;
  }
}
