import 'package:flutter/material.dart';

import '../screens/apk_list_screen.dart';
import '../screens/app_list_screen.dart';
import '../stores/bottom_navigation.dart';
import '../widgets/bottom_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with BottomNavigationStoreMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildTab(Widget child, int index) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: bottomNavigationStore,
        builder: (BuildContext context, Widget? _) {
          return Visibility(
            maintainState: true,
            visible: bottomNavigationStore.currentIndex == 0,
            child: child,
          );
        },
      ),
    );
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
      body: Stack(
        children: <Widget>[
          _buildTab(const AppListScreen(), 0),
          _buildTab(const ApkListScreen(), 0),
          _buildTab(const Placeholder(), 0),
        ],
      ),
    );
  }
}
