import 'package:flutter/material.dart';
import '../setup.dart';
import '../utils/context_of.dart';
import 'indexed_collection_store.dart';

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

mixin ContextualMenuStoreMixin {
  ContextualMenuStore? _menuStore;
  ContextualMenuStore get menuStore =>
      _menuStore ??= getIt<ContextualMenuStore>();
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
    if (_stack.length == 1) return;
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

class DefaultContextualMenuPopHandler<T> extends StatefulWidget {
  const DefaultContextualMenuPopHandler({
    super.key,
    this.searchableStore,
    this.selectableStore,
    required this.child,
  });

  final SearchableStoreMixin<T>? searchableStore;
  final SelectableStoreMixin<T>? selectableStore;
  final Widget child;

  @override
  State<DefaultContextualMenuPopHandler<T>> createState() =>
      _DefaultContextualMenuPopHandlerState<T>();
}

class _DefaultContextualMenuPopHandlerState<T>
    extends State<DefaultContextualMenuPopHandler<T>> {
  ContextualMenuStore get _menuStore => context.of<ContextualMenuStore>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        switch (_menuStore.context) {
          case MenuContext.normal:
            return true;
          case MenuContext.search:
            widget.searchableStore?.disableSearch();
            break;
          case MenuContext.selection:
            widget.selectableStore?.clearSelection();
            break;
        }

        _menuStore.popMenu();

        return false;
      },
      child: widget.child,
    );
  }
}
