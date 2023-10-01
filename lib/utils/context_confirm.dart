import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../setup.dart';
import '../stores/settings_store.dart';
import 'app_localization_strings.dart';

Future<bool> showConfirmationModal({
  required BuildContext context,
  String? message,
  bool force = false,
}) async {
  // Bad practice, avoid adding unnecessary coupling like this, for now it will work
  // but I'll probably remove in the future.
  if (!getIt<SettingsStore>().shouldConfirmIrreversibleActions && !force) {
    return true;
  }

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(message ?? context.strings.areYouSure),
        content: Text(
          context.strings.thisIsIrreversible,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              context.pop<bool>(false);
            },
            child: Text(context.strings.cancel),
          ),
          TextButton(
            onPressed: () {
              context.pop<bool>(true);
            },
            child: Text(
              context.strings.confirm,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed == null) return false;

  return confirmed;
}
