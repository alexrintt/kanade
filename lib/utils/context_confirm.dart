import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../setup.dart';
import '../stores/settings_store.dart';

Future<bool> showConfirmationModal({required BuildContext context}) async {
  // Bad practice, avoid adding unnecessary coupling like this, for now it will work
  // but I'll probably remove in the future.
  if (!getIt<SettingsStore>().confirmIrreversibleActions) {
    return true;
  }

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text(
          'This is a irreversible action, be sure you want to do it.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              context.pop<bool>(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.pop<bool>(true);
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed == null) return false;

  return confirmed;
}
