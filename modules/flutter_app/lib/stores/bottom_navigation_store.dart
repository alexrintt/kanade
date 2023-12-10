import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../setup.dart';

mixin BottomNavigationStoreMixin {
  BottomNavigationStore? _bottomNavigationStore;
  BottomNavigationStore get bottomNavigationStore =>
      _bottomNavigationStore ??= getIt<BottomNavigationStore>();
}

@Singleton()
class BottomNavigationStore extends ChangeNotifier {
  BottomNavigationStore();

  int initialIndex = 0;

  int? _index;

  int get currentIndex => _index ?? initialIndex;

  void setCurrentIndex(int index) {
    _index = index;
    notifyListeners();
  }

  void navigateToAppList() => setCurrentIndex(0);
}
