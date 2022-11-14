import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:kanade/pages/settings_page.dart';
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
              '${store.selected.length} of ${store.displayableApps.length}');
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
          tooltip: 'Extract All Selected',
          onTap: () async {
            try {
              showLoadingDialog(context, 'Extracting Apk\'s...');

              final extractedApks = await store.extractSelectedApks();

              final result = extractedApks.result;

              final extractedTo = extractedApks.extractions.isEmpty
                  ? null
                  : extractedApks.extractions.first.apk?.parent;

              if (!mounted) return;

              if (result.failed) {
                showToast(context,
                    'Sorry, we can\'t export any of these apks because they are restricted by the OS.');
              } else if (result.permissionWasDenied) {
                showToast(context,
                    'To export the apk we need permission to write to your storage.');
              } else if (result.someMayFailed) {
                showToast(context,
                    'Some apk\'s are located in ${extractedTo?.absolute} but some could not be extracted.');
              } else if (result.success) {
                showToast(context,
                    'All apks were extracted to ${extractedTo?.absolute}');
              }
            } finally {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Pixel.download),
        ),
        AppIconButton(
          tooltip: 'Select/Unselect All',
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
        tooltip: 'Back to default view',
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
          onTap: menuStore.pushSearchMenu,
          icon: const Icon(Pixel.search),
          tooltip: 'Search Packages/Apps',
        ),
        AppIconButton(
          onTap: _openSettingsPage,
          icon: const Icon(Pixel.sliders),
          tooltip: 'Configure Your Preferences',
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

        if (current.isNormal) {
          return _buildNormalMenu();
        } else if (current.isSelection) {
          return _buildSelectionMenu();
        } else if (current.isSearch) {
          return _buildSearchMenu();
        }

        throw Exception('Got invalid menu configuration: $current');
      },
    );
  }
}
