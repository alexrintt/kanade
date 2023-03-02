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
          bottom: theme.navigationBarTheme.height!,
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
  Widget _buildTab(Widget child, int index) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: bottomNavigationStore,
        builder: (BuildContext context, Widget? _) {
          return Visibility(
            maintainState: true,
            visible: bottomNavigationStore.currentIndex == index,
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
      extendBody: true,
      body: Stack(
        children: <Widget>[
          _buildTab(const AppListScreen(), 0),
          _buildTab(const BackgroundTaskListScreen(), 1),
          _buildTab(const FileListScreen(), 2),
        ],
      ),
    );
  }
}
