import 'package:flutter/cupertino.dart';
import 'package:kanade/setup.dart';

class MenuContext {
  final int value;

  const MenuContext._(this.value);

  static const normal = MenuContext._(0);
  static const selection = MenuContext._(1);
  static const search = MenuContext._(2);

  bool get isNormal => value == 0;

  bool get isSelection => value == 1;

  bool get isSearch => value == 2;
}

mixin ContextualMenuStoreConsumer<T extends StatefulWidget> on State<T> {
  final menuStore = getIt<ContextualMenuStore>();
}

/// Store to manage the current active menu
class ContextualMenuStore extends ChangeNotifier {
  MenuContext context = MenuContext.normal;

  void showDefaultMenu() => _showMenuAs(MenuContext.normal);

  void showSearchMenu() => _showMenuAs(MenuContext.search);

  void showSelectionMenu() => _showMenuAs(MenuContext.selection);

  void _showMenuAs(MenuContext target) {
    if (context == target) return;

    context = target;

    notifyListeners();
  }
}
