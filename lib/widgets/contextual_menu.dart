import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:kanade/pages/settings_page.dart';
import 'package:kanade/utils/app_localization_strings.dart';
import 'package:kanade/widgets/animated_app_name.dart';
import 'package:pixelarticons/pixelarticons.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';
import 'package:kanade/widgets/toast.dart';
import 'package:pixelarticons/pixel.dart';

import 'app_icon_button.dart';

class ContextualMenu extends StatefulWidget {
  const ContextualMenu({Key? key}) : super(key: key);

  @override
  _ContextualMenuState createState() => _ContextualMenuState();
}

/// We cannot split each [SliverAppBar] into multiple Widgets because we are rebuilding
/// only the [SliverAppBar] and not the entire [CustomScrollView]
class _ContextualMenuState extends State<ContextualMenu>
    with ContextualMenuStoreConsumer, DeviceAppsStoreConsumer {
  Future<void> _openSettingsPage() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
  }

  Widget _buildSelectionMenu() {
    return SliverAppBar(
      title: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          return Text(
            '${store.selected.length} ${context.strings.ofN} ${store.displayableApps.length}',
          );
        },
      ),
      floating: true,
      pinned: false,
      leading: IconButton(
        onPressed: () {
          menuStore.popMenu();
          store.clearSelection();
        },
        icon: const Icon(Pixel.arrowleft),
      ),
      actions: [
        AppIconButton(
          tooltip: context.strings.extractAllSelected,
          onTap: () async {
            try {
              showLoadingDialog(
                context,
                '${context.strings.extractingApks}...',
              );

              final extractedApks = await store.extractSelectedApks();

              final result = extractedApks.result;

              final extractedTo = extractedApks.extractions.isEmpty
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
                    context.strings.someApkWereNotExtracted.withArgs(
                      [extractedTo.absolute.toString()],
                    ),
                  );
                } else {
                  showToast(
                    context,
                    context.strings.someApkWereNotExtractedPlain,
                  );
                }
              } else if (result.success) {
                if (extractedTo != null) {
                  showToast(
                    context,
                    context.strings.allApksWereSuccessfullyExtracted.withArgs(
                      [extractedTo.absolute.toString()],
                    ),
                  );
                } else {
                  showToast(
                    context,
                    context.strings.allApksWereSuccessfullyExtractedPlain,
                  );
                }
              }
            } finally {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Pixel.download),
        ),
        AppIconButton(
          tooltip: context.strings.selectUnselectAll,
          onTap: store.toggleSelectAll,
          icon: AnimatedBuilder(
            animation: store,
            builder: (context, child) {
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
      title: TextField(
        cursorColor: context.textTheme.bodyText1!.color,
        autofocus: true,
        autocorrect: false,
        onChanged: store.search,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      ),
      floating: true,
      pinned: false,
      leading: AppIconButton(
        onTap: () {
          menuStore.popMenu();
          store.disableSearch();
        },
        icon: const Icon(Pixel.arrowleft),
        tooltip: context.strings.exitSearch,
      ),
    );
  }

  Widget _buildNormalMenu() {
    return SliverAppBar(
      titleSpacing: k4dp,
      title: const SizedBox(
        height: kToolbarHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedAppName(),
        ),
      ),
      actions: [
        AppIconButton(
          onTap: () => showDialog(
            context: context,
            builder: (context) => const ChangeThemeDialog(),
          ),
          icon: const Icon(Pixel.sun),
          tooltip: context.strings.changeTheme,
        ),
        AppIconButton(
          onTap: menuStore.pushSearchMenu,
          icon: const Icon(Pixel.search),
          tooltip: context.strings.searchPackagesAndApps,
        ),
        AppIconButton(
          onTap: _openSettingsPage,
          icon: const Icon(Pixel.sliders),
          tooltip: context.strings.openSettingsPage,
        ),
      ],
      floating: true,
      pinned: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: menuStore,
      builder: (context, child) {
        final current = menuStore.context;

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
