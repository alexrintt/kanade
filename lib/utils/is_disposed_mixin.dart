import 'package:flutter/cupertino.dart';

mixin IsDisposedMixin on ChangeNotifier {
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;

    super.dispose();
  }
}
