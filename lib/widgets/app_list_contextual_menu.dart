import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../stores/contextual_menu_store.dart';
import '../stores/device_apps_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_localization_strings.dart';
import '../utils/context_of.dart';
import 'app_icon_button.dart';
import 'sliver_app_top_bar.dart';
import 'toast.dart';

class AppListContextualMenu extends StatefulWidget {
  const AppListContextualMenu({
    super.key,
    this.onSearch,
  });

  final VoidCallback? onSearch;

  @override
  _AppListContextualMenuState createState() => _AppListContextualMenuState();
}

/// We cannot split each [SliverAppBar] into multiple Widgets because we are rebuilding
/// only the [SliverAppBar] and not the entire [CustomScrollView]
class _AppListContextualMenuState extends State<AppListContextualMenu>
    with DeviceAppsStoreMixin, SettingsStoreMixin {
  ContextualMenuStore get _menuStore => context.of<ContextualMenuStore>();

  Color? get _appBarColorOverride =>
      store.apps.isEmpty ? Colors.transparent : null;

  Widget _buildSelectionMenu() {
    return SliverAppBar(
      backgroundColor: _appBarColorOverride,
      title: AnimatedBuilder(
        animation: store,
        builder: (BuildContext context, Widget? child) {
          return Text(
            '${store.selected.length} ${context.strings.ofN} ${store.apps.length}',
          );
        },
      ),
      pinned: !settingsStore
          .getBoolPreference(SettingsBoolPreference.hideAppBarOnScroll),
      floating: true,
      leading: IconButton(
        onPressed: () {
          _menuStore.popMenu();
          store.clearSelection();
        },
        icon: const Icon(Pixel.arrowleft),
      ),
      actions: <Widget>[
        AppIconButton(
          tooltip: context.strings.extractAllSelected,
          onTap: () async {
            try {
              store.showProgressIndicator();

              final MultipleApkExtraction extractedApks =
                  await store.extractSelectedApks();

              final MultipleResult result = extractedApks.result;

              final Directory? extractedTo = extractedApks.extractions.isEmpty
                  ? null
                  : extractedApks.extractions.first.apk?.parent;

              if (!mounted) return;

              if (result.failed) {
                showToast(
                  context,
                  context.strings
                      .sorryWeCouldNotExportAnyApkBecauseTheyAreRestrictedByTheOS,
                );
              } else if (result.permissionWasDenied) {
                showToast(
                  context,
                  context.strings.permissionDenied,
                );
              } else if (result.someMayFailed) {
                if (extractedTo != null) {
                  showToast(
                    context,
                    context.strings.someApkWereNotExtracted(
                      extractedTo.absolute.toString(),
                    ),
                  );
                } else {
                  showToast(
                    context,
                    context.strings.someApkWereNotExtractedPlain,
                  );
                }
              } else if (result.success) {
                // the bottom bar indicates the success by showing a badge indicator.
              }
            } finally {
              store.hideProgressIndicator();
            }
          },
          icon: const Icon(Pixel.download),
        ),
        AppIconButton(
          tooltip: context.strings.selectUnselectAll,
          onTap: store.toggleSelectAll,
          icon: AnimatedBuilder(
            animation: store,
            builder: (BuildContext context, Widget? child) {
              if (store.isAllSelected) {
                return Icon(Pixel.checkbox, color: context.colorScheme.primary);
              }

              return const Icon(Pixel.checkboxon);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchMenu() {
    return SliverAppBar(
      backgroundColor: _appBarColorOverride,
      title: TextField(
        cursorColor: context.textTheme.bodyLarge!.color,
        autofocus: true,
        autocorrect: false,
        onChanged: store.search,
        style: const TextStyle(decorationThickness: 0),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
      pinned: !settingsStore
          .getBoolPreference(SettingsBoolPreference.hideAppBarOnScroll),
      floating: true,
      leading: AppIconButton(
        onTap: () {
          _menuStore.popMenu();
          store.disableSearch();
        },
        icon: const Icon(Pixel.arrowleft),
        tooltip: context.strings.exitSearch,
      ),
    );
  }

  Widget _buildNormalMenu() {
    return SliverAppTopBar(
      backgroundColor: _appBarColorOverride,
      onSearch: widget.onSearch,
      pinned: !settingsStore
          .getBoolPreference(SettingsBoolPreference.hideAppBarOnScroll),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _menuStore,
      builder: (BuildContext context, Widget? child) {
        final MenuContext current = _menuStore.context;

        switch (current) {
          case MenuContext.selection:
            return _buildSelectionMenu();
          case MenuContext.search:
            return _buildSearchMenu();
          case MenuContext.normal:
            return _buildNormalMenu();
        }
      },
    );
  }
}
