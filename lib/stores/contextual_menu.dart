import 'package:flutter/material.dart';
import '../setup.dart';

enum MenuContext {
  normal,
  selection,
  search,
}

extension MenuContextAlias on MenuContext {
  bool get isNormal => this == MenuContext.normal;
  bool get isSelection => this == MenuContext.selection;
  bool get isSearch => this == MenuContext.search;
}

mixin ContextualMenuStoreMixin<T extends StatefulWidget> on State<T> {
  ContextualMenuStore? _menuStore;
  ContextualMenuStore get menuStore =>
      _menuStore ??= getIt<ContextualMenuStore>();

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _menuStore = null; // Refresh store instance when updating the widget
  }
}

/// Store to manage the current active menu.
class ContextualMenuStore extends ChangeNotifier {
  MenuContext get context => _stack.last;

  final List<MenuContext> _stack = <MenuContext>[MenuContext.normal];

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
