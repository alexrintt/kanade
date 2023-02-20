import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../pages/settings_page.dart';
import '../utils/app_localization_strings.dart';
import '../utils/open_settings_page.dart';
import 'animated_app_name.dart';
import 'app_icon_button.dart';

class SliverAppTopBar extends StatefulWidget {
  const SliverAppTopBar({super.key, this.onSearch});

  final VoidCallback? onSearch;

  @override
  State<SliverAppTopBar> createState() => _SliverAppTopBarState();
}

class _SliverAppTopBarState extends State<SliverAppTopBar> {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      titleSpacing: k10dp,
      title: const SizedBox(
        height: kToolbarHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedAppName(),
        ),
      ),
      actions: <Widget>[
        AppIconButton(
          onTap: () => showDialog(
            context: context,
            builder: (BuildContext context) => const ChangeThemeDialog(),
          ),
          icon: Icon(
            Pixel.sun,
            color: context.isDark ? null : context.primaryColor,
          ),
          tooltip: context.strings.changeTheme,
        ),
        if (widget.onSearch != null)
          AppIconButton(
            onTap: widget.onSearch,
            icon: Icon(
              Pixel.search,
              color: context.isDark ? null : context.primaryColor,
            ),
            tooltip: context.strings.searchPackagesAndApps,
          ),
        AppIconButton(
          onTap: context.openSettingsPage,
          icon: Icon(
            Pixel.morevertical,
            color: context.isDark ? null : context.primaryColor,
          ),
          tooltip: context.strings.openSettingsPage,
        ),
      ],
      floating: true,
    );
  }
}