import 'package:flutter/material.dart';
import '../setup.dart';

mixin BottomNavigationStoreMixin<T extends StatefulWidget> on State<T> {
  BottomNavigationStore? _bottomNavigationStore;
  BottomNavigationStore get bottomNavigationStore =>
      _bottomNavigationStore ??= getIt<BottomNavigationStore>();

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bottomNavigationStore =
        null; // Refresh store instance when updating the widget
  }
}

class BottomNavigationStore extends ChangeNotifier {
  BottomNavigationStore({this.initialIndex = 0});

  int initialIndex;

  int? _index;

  int get currentIndex => _index ?? initialIndex;

  void setCurrentIndex(int index) {
    _index = index;
    notifyListeners();
  }
}
