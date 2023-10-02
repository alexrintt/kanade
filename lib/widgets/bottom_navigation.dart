import 'package:flutter/material.dart';

import '../stores/background_task_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
import '../utils/app_localization_strings.dart';
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
        final Widget navigationBar = NavigationBar(
          selectedIndex: widget.index,
          onDestinationSelected: _select,
          destinations: <Widget>[
            NavigationDestination(
              icon: Icon(
                AppIcons.apps.data,
                size: kDefaultIconSize,
              ),
              label: context.strings.apps,
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
              label: context.strings.extracted,
            ),
            NavigationDestination(
              icon: Icon(
                AppIcons.folder.data,
                size: kDefaultIconSize,
              ),
              label: context.strings.allFiles,
            ),
          ],
        );

        return navigationBar;
      },
    );
  }
}
