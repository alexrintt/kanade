import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/background_task_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
import 'multi_animated_builder.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({
    super.key,
    required this.onChange,
    required this.index,
  }) : assert(index >= 0 && index < 4);

  final void Function(int) onChange;
  final int index;

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation>
    with SettingsStoreMixin, BackgroundTaskStoreMixin {
  void _select(int index) {
    widget.onChange(index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiAnimatedBuilder(
      animations: <Listenable>[
        settingsStore,
        backgroundTaskStore,
      ],
      builder: (BuildContext context, Widget? child) {
        final bool transparentNavigationBar =
            settingsStore.transparentNavigationBar;

        Widget navigationBar = NavigationBar(
          backgroundColor: transparentNavigationBar ? Colors.transparent : null,
          shadowColor: transparentNavigationBar ? Colors.transparent : null,
          surfaceTintColor:
              transparentNavigationBar ? Colors.transparent : null,
          elevation: transparentNavigationBar ? 0.0 : null,
          selectedIndex: widget.index,
          onDestinationSelected: _select,
          destinations: <Widget>[
            NavigationDestination(
              icon: Icon(
                AppIcons.apps.data,
                size: kDefaultIconSize,
              ),
              label: 'Apps',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text(backgroundTaskStore.badgeCount.toString()),
                isLabelVisible: backgroundTaskStore.badgeCount != 0,
                child: Icon(
                  AppIcons.apk.data,
                  size: kDefaultIconSize,
                ),
              ),
              label: 'Extracted',
            ),
            NavigationDestination(
              icon: Icon(
                AppIcons.folder.data,
                size: kDefaultIconSize,
              ),
              label: 'All files',
            ),
          ],
        );

        if (transparentNavigationBar) {
          navigationBar = Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: context.primaryColor,
                  width: 2,
                ),
              ),
            ),
            height: context.theme.navigationBarTheme.height,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: k3dp, sigmaY: k3dp),
                child: navigationBar,
              ),
            ),
          );
        }

        return navigationBar;
      },
    );
  }
}
