import 'package:flutter/material.dart';
import '../setup.dart';

mixin BottomNavigationStoreMixin {
  BottomNavigationStore? _bottomNavigationStore;
  BottomNavigationStore get bottomNavigationStore =>
      _bottomNavigationStore ??= getIt<BottomNavigationStore>();
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

  void navigateToAppList() => setCurrentIndex(0);
}
