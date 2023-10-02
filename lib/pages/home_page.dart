import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../screens/app_list_screen.dart';
import '../screens/background_task_list_screen.dart';
import '../screens/file_list_screen.dart';
import '../stores/bottom_navigation_store.dart';
import '../widgets/bottom_navigation.dart';

extension BottomSpacer on BuildContext {
  Widget get bottomSpacer => Padding(
        padding: EdgeInsets.only(
          bottom: theme.navigationBarTheme.height ?? kToolbarHeight * 2,
        ),
      );

  Widget get bottomSliverSpacer => SliverList(
        delegate: SliverChildListDelegate(
          <Widget>[bottomSpacer],
        ),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with BottomNavigationStoreMixin {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    bottomNavigationStore.addListener(() {
      if (_pageController.hasClients) {
        if (_pageController.page!.toInt() !=
            bottomNavigationStore.currentIndex) {
          _pageController.jumpToPage(bottomNavigationStore.currentIndex);
        }
      }
    });
  }

  @override
  void dispose() {
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
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const <Widget>[
          AppListScreen(),
          BackgroundTaskListScreen(),
          FileListScreen(),
        ],
      ),
    );
  }
}
