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
        final bool transparentBottomNavigationBar =
            settingsStore.getBoolPreference(
          SettingsBoolPreference.transparentBottomNavigationBar,
        );

        Widget navigationBar = NavigationBar(
          backgroundColor:
              transparentBottomNavigationBar ? Colors.transparent : null,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          selectedIndex: widget.index,
          onDestinationSelected: _select,
          destinations: <Widget>[
            const NavigationDestination(
              icon: Icon(
                AppIcons.apps,
                size: kDefaultIconSize,
              ),
              label: 'Apps',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text(backgroundTaskStore.badgeCount.toString()),
                isLabelVisible: backgroundTaskStore.badgeCount != 0,
                child: const Icon(
                  AppIcons.apk,
                  size: kDefaultIconSize,
                ),
              ),
              label: 'Apks',
            ),
            const NavigationDestination(
              icon: Icon(
                AppIcons.folder,
                size: kDefaultIconSize,
              ),
              label: 'Files',
            ),
          ],
        );

        if (transparentBottomNavigationBar) {
          navigationBar = SizedBox(
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
