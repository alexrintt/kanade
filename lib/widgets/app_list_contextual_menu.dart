import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/contextual_menu_store.dart';
import '../stores/device_apps_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
import '../utils/app_localization_strings.dart';
import '../utils/context_of.dart';
import '../utils/stringify_uri_location.dart';
import 'animated_flip_counter.dart';
import 'app_icon_button.dart';
import 'sliver_app_bar_translucent.dart';
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
    return SliverAppBarTranslucent(
      backgroundColor: _appBarColorOverride,
      title: AnimatedBuilder(
        animation: store,
        builder: (BuildContext context, Widget? child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedCount(count: store.selected.length),
              Text(
                ' ${context.strings.ofN} ',
              ),
              AnimatedCount(count: store.apps.length),
            ],
          );
        },
      ),
      pinned: !settingsStore
          .getBoolPreference(SettingsBoolPreference.hideAppBarOnScroll),
      leading: IconButton(
        onPressed: () {
          _menuStore.popMenu();
          store.unselectAll();
        },
        icon: Icon(
          AppIcons.arrowLeft.data,
          size: kDefaultIconSize,
        ),
      ),
      actions: <Widget>[
        AppIconButton(
          tooltip: context.strings.extractAllSelected,
          onTap: () async {
            try {
              store.showProgressIndicator();

              final MultipleExtraction extractedApks =
                  await store.extractSelectedApks();

              final MultipleExtractionResult result = extractedApks.result;

              final Uri? extractedTo = settingsStore.exportLocation;

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
                      stringifyTreeUri(extractedTo)!,
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
          icon: Icon(AppIcons.download.data, size: AppIcons.download.size),
        ),
        AppIconButton(
          tooltip: context.strings.selectUnselectAll,
          onTap: store.toggleSelectAll,
          icon: AnimatedBuilder(
            animation: store,
            builder: (BuildContext context, Widget? child) {
              if (store.isAllSelected) {
                return Icon(
                  AppIcons.checkboxSelected.data,
                  size: kDefaultIconSize,
                  color: context.colorScheme.primary,
                );
              }

              return Icon(
                AppIcons.checkboxUnselected.data,
                size: kDefaultIconSize,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchMenu() {
    return SliverAppBarTranslucent(
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
      leading: AppIconButton(
        onTap: () {
          _menuStore.popMenu();
          store.disableSearch();
        },
        icon: Icon(
          AppIcons.arrowLeft.data,
          size: kDefaultIconSize,
        ),
        tooltip: context.strings.exitSearch,
      ),
    );
  }

  Widget _buildNormalMenu() {
    return SliverAppBarGlobal(
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
