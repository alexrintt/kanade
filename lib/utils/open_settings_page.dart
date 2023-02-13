import 'package:flutter/material.dart';

import '../pages/settings_page.dart';

extension OpenSettingsPage on BuildContext {
  Future<void> openSettingsPage() async {
    await Navigator.push(
      this,
      MaterialPageRoute<void>(
        builder: (_) => const SettingsPage(),
      ),
    );
  }
}
