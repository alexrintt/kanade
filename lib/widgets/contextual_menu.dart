import 'package:flutter/material.dart';
import 'package:kanade/constants/app_colors.dart';
import 'package:kanade/constants/strings.dart';
import 'package:kanade/icons/pixel_art_icons.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';
import 'package:kanade/widgets/toast.dart';
import 'package:url_launcher/url_launcher.dart';

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
          menuStore.showDefaultMenu();
          store.restoreToDefault();
        },
        icon: const Icon(PixelArt.arrow_left),
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

              if (result.failed) {
                showToast(context,
                    'Sorry, we can\'t export any of these apk\'s because they are restricted by the OS');
              } else if (result.permissionWasDenied) {
                showToast(context,
                    'To export the apk we need permission to write to your storage');
              } else if (result.someMayFailed) {
                showToast(context,
                    'Some apk\'s are located in ${extractedTo?.absolute} but some apk\'s could not be extracted');
              } else if (result.success) {
                showToast(context,
                    'All apk\'s are located in ${extractedTo?.absolute}!');
              }
            } finally {
              Navigator.pop(context);
            }
          },
          icon: const Icon(PixelArt.download),
        ),
        AppIconButton(
          tooltip: 'Select/Unselect All',
          onTap: store.toggleSelectAll,
          icon: AnimatedBuilder(
            animation: store,
            builder: (context, child) {
              if (store.isAllSelected) {
                return const Icon(PixelArt.checkbox, color: kAccent100);
              }

              return const Icon(PixelArt.checkbox_on);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchMenu() {
    return SliverAppBar(
      title: TextField(
        cursorColor: Colors.white,
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
          menuStore.showDefaultMenu();
          store.restoreToDefault();
        },
        icon: const Icon(PixelArt.arrow_left),
        tooltip: 'Back to default view',
      ),
    );
  }

  Widget _buildNormalMenu() {
    return SliverAppBar(
      titleSpacing: 0,
      title: Opacity(
        opacity: 0.3,
        child: Row(
          children: [
            Image.asset(
              'assets/images/pixel_animation.gif',
              filterQuality: FilterQuality.none,
              fit: BoxFit.contain,
              height: 70,
            ),
            const Text(
              'KANADE',
              style: TextStyle(
                fontFamily: 'Forward',
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppIconButton(
          onTap: () => launchUrl(Uri.parse(kRepositoryUrl)),
          icon: const Icon(PixelArt.android),
          tooltip: 'Open-Source Repository',
        ),
        AppIconButton(
          onTap: menuStore.showSearchMenu,
          icon: const Icon(PixelArt.search),
          tooltip: 'Search Packages/Apps',
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
