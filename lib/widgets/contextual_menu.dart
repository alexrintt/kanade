import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../stores/contextual_menu_store.dart';
import '../stores/device_apps.dart';
import '../utils/app_localization_strings.dart';
import 'app_icon_button.dart';
import 'sliver_app_top_bar.dart';
import 'toast.dart';

class ContextualMenu extends StatefulWidget {
  const ContextualMenu({
    super.key,
    this.onSearch,
  });

  final VoidCallback? onSearch;

  @override
  _ContextualMenuState createState() => _ContextualMenuState();
}

/// We cannot split each [SliverAppBar] into multiple Widgets because we are rebuilding
/// only the [SliverAppBar] and not the entire [CustomScrollView]
class _ContextualMenuState extends State<ContextualMenu>
    with
        ContextualMenuStoreMixin<ContextualMenu>,
        DeviceAppsStoreMixin<ContextualMenu> {
  Widget _buildSelectionMenu() {
    return SliverAppBar(
      title: AnimatedBuilder(
        animation: store,
        builder: (BuildContext context, Widget? child) {
          return Text(
            '${store.selected.length} ${context.strings.ofN} ${store.displayableApps.length}',
          );
        },
      ),
      floating: true,
      leading: IconButton(
        onPressed: () {
          menuStore.popMenu();
          store.clearSelection();
        },
        icon: const Icon(Pixel.arrowleft),
      ),
      actions: <Widget>[
        AppIconButton(
          tooltip: context.strings.extractAllSelected,
          onTap: () async {
            try {
              unawaited(
                showLoadingDialog(
                  context,
                  '${context.strings.extractingApks}...',
                ),
              );

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
                if (extractedTo != null) {
                  showToast(
                    context,
                    context.strings.allApksWereSuccessfullyExtracted(
                      extractedTo.absolute.toString(),
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
      title: TextField(
        cursorColor: context.textTheme.bodyLarge!.color,
        autofocus: true,
        autocorrect: false,
        onChanged: store.search,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      ),
      floating: true,
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
    return SliverAppTopBar(onSearch: widget.onSearch);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: menuStore,
      builder: (BuildContext context, Widget? child) {
        final MenuContext current = menuStore.context;

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
