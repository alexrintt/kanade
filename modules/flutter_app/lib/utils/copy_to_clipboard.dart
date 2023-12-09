import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/toast.dart';
import 'app_localization_strings.dart';

Future<void> copyTextToClipboard(String text) =>
    Clipboard.setData(ClipboardData(text: text));

extension CopyTextToClipboardAndShowToast on BuildContext {
  Future<void> copyTextToClipboardAndShowToast(String text) async {
    await copyTextToClipboard(text);
    if (mounted) showToast(this, strings.copiedToClipboard);
  }
}
