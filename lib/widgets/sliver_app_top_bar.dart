import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../pages/settings_page.dart';
import '../utils/app_icons.dart';
import '../utils/app_localization_strings.dart';
import '../utils/open_settings_page.dart';
import 'animated_app_name.dart';
import 'app_icon_button.dart';

class SliverAppTopBar extends StatefulWidget {
  const SliverAppTopBar({
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
  State<SliverAppTopBar> createState() => _SliverAppTopBarState();
}

class _SliverAppTopBarState extends State<SliverAppTopBar> {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      titleSpacing: k10dp,
      backgroundColor: widget.backgroundColor,
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
        AppIconButton(
          onTap: () => showDialog(
            context: context,
            builder: (BuildContext context) => const ChangeThemeDialog(),
          ),
          icon: Icon(
            AppIcons.styling.data,
            color: context.isDark ? null : context.primaryColor,
            size: kDefaultIconSize,
          ),
          tooltip: context.strings.changeTheme,
        ),
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
