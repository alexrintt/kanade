import 'package:flutter/material.dart';

import '../screens/apk_list_screen.dart';
import '../screens/app_list_screen.dart';
import '../stores/bottom_navigation.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/keep_alive.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with BottomNavigationStoreMixin<HomePage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    bottomNavigationStore.addListener(bottomNavigationListener);
  }

  void bottomNavigationListener() {
    _pageController.jumpToPage(bottomNavigationStore.currentIndex);
  }

  @override
  void dispose() {
    bottomNavigationStore.removeListener(bottomNavigationListener);

    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AnimatedBuilder(
        animation: bottomNavigationStore,
        builder: (BuildContext context, Widget? child) {
          return BottomNavigation(
            index: bottomNavigationStore.currentIndex,
            onChange: bottomNavigationStore.setCurrentIndex,
          );
        },
      ),
      body: PageView(
        pageSnapping: false,
        controller: _pageController,
        children: const <Widget>[
          Keep(child: AppListScreen()),
          Keep(child: ApkListScreen()),
        ],
      ),
    );
  }
}
