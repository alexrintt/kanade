import 'package:flutter/material.dart' hide SliverAppBar;
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/settings_store.dart';
import '../stores/theme_store.dart';
import '../utils/app_icons.dart';
import '../utils/app_localization_strings.dart';
import '../utils/open_settings_page.dart';
import '../widgets/sliver_app_bar.dart';
import 'animated_app_name.dart';
import 'app_icon_button.dart';
import 'sliver_app_bar_translucent.dart';

/// Global customized [SliverAppBar] app.
class SliverAppBarGlobal extends StatefulWidget {
  const SliverAppBarGlobal({
    super.key,
    this.onSearch,
    this.backgroundColor,
    this.floating = true,
    this.pinned = false,
    this.bottom,
    this.actions,
  });

  final VoidCallback? onSearch;
  final Color? backgroundColor;
  final bool floating;
  final bool pinned;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  @override
  State<SliverAppBarGlobal> createState() => _SliverAppBarGlobalState();
}

class _SliverAppBarGlobalState extends State<SliverAppBarGlobal>
    with SettingsStoreMixin, ThemeStoreMixin<SliverAppBarGlobal> {
  @override
  Widget build(BuildContext context) {
    return SliverAppBarTranslucent(
      scrolledUnderElevation:
          settingsStore.transparentNavigationBar ? 0.0 : null,
      titleSpacing: k10dp,
      backgroundColor: settingsStore.transparentNavigationBar
          ? Colors.transparent
          : widget.backgroundColor,
      elevation: settingsStore.transparentNavigationBar ? 0.0 : null,
      shadowColor:
          settingsStore.transparentNavigationBar ? Colors.transparent : null,
      surfaceTintColor:
          settingsStore.transparentNavigationBar ? Colors.transparent : null,
      foregroundColor:
          settingsStore.transparentNavigationBar ? Colors.transparent : null,
      title: const SizedBox(
        height: kToolbarHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedAppName(),
        ),
      ),
      bottom: widget.bottom,
      actions: <Widget>[
        ...?widget.actions,
        if (widget.onSearch != null)
          AppIconButton(
            onTap: widget.onSearch,
            icon: Icon(
              AppIcons.search.data,
              color: context.isDark ? null : context.primaryColor,
              size: kDefaultIconSize,
            ),
            tooltip: context.strings.searchPackagesAndApps,
          ),
        AppIconButton(
          onTap: context.openSettingsPage,
          icon: Icon(
            AppIcons.settings.data,
            color: context.isDark ? null : context.primaryColor,
            size: kDefaultIconSize,
          ),
          tooltip: context.strings.openSettingsPage,
        ),
      ],
      floating: widget.floating,
      pinned: widget.pinned,
    );
  }
}
