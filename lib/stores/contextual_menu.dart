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
  ContextualMenuStore? _menuStore;
  ContextualMenuStore get menuStore =>
      _menuStore ??= getIt<ContextualMenuStore>();
}

/// Store to manage the current active menu.
class ContextualMenuStore extends ChangeNotifier {
  MenuContext get context => _stack.last;

  final List<MenuContext> _stack = [MenuContext.normal];

  void _pushMenu(MenuContext context) {
    if (_stack.last == context) return;
    _stack.add(context);
    notifyListeners();
  }

  void pushSelectionMenu() {
    return _pushMenu(MenuContext.selection);
  }

  void pushSearchMenu() {
    return _pushMenu(MenuContext.search);
  }

  void pushDefaultMenu() {
    return _pushMenu(MenuContext.normal);
  }

  void popMenu() {
    _stack.removeLast();
    notifyListeners();
  }

  void clearStack() {
    _stack
      ..clear()
      ..add(MenuContext.normal);
    notifyListeners();
  }
}
