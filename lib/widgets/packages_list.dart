import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';
import 'package:kanade/utils/app_localization_strings.dart';
import 'package:kanade/widgets/animated_app_name.dart';
import 'package:kanade/widgets/app_version_info.dart';
import 'package:kanade/widgets/package_tile.dart';
import 'package:kanade/widgets/toast.dart';

import 'contextual_menu.dart';
import 'multi_animated_builder.dart';

class PackagesList extends StatefulWidget {
  const PackagesList({Key? key}) : super(key: key);

  @override
  _PackagesListState createState() => _PackagesListState();
}

class _PackagesListState extends State<PackagesList>
    with DeviceAppsStoreConsumer, ContextualMenuStoreConsumer {
  void _onLongPress(Application package) {
    menuStore.pushSelectionMenu();
    store.toggleSelect(package);
  }

  void _onPressed(Application package) async {
    if (menuStore.context.isSelection) {
      store.toggleSelect(package);
    } else {
      try {
        showLoadingDialog(context, context.strings.extractingApks);

        final extraction = await store.extractApk(package);

        if (!mounted) return;

        if (extraction.result.success) {
          showToast(context,
              '${context.strings.extractedTo} ${extraction.apk!.path}');
        } else if (extraction.result.permissionWasDenied) {
          showToast(context, context.strings.permissionDenied);
        } else if (extraction.result.restrictedPermission) {
          showToast(context, context.strings.permissionRestrictedByAndroid);
        } else if (extraction.result.extractionNotAllowed) {
          showToast(
            context,
            context.strings.operationNotAllowedMayBeProtectedPackage,
          );
        }
      } finally {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        switch (menuStore.context) {
          case MenuContext.normal:
            return true;
          case MenuContext.search:
            store.disableSearch();
            break;
          case MenuContext.selection:
            store.clearSelection();
            break;
        }

        menuStore.popMenu();

        return false;
      },
      child: MultiAnimatedBuilder(
        animations: [store, menuStore],
        builder: (context, child) => CustomScrollView(
          slivers: [
            const ContextualMenu(),
            MultiAnimatedBuilder(
              animations: [store, menuStore],
              builder: (context, child) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: k3dp),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final current = store.displayableApps[index];

                        return PackageTile(
                          current,
                          showCheckbox: menuStore.context.isSelection,
                          onLongPress: () => _onLongPress(current),
                          onPressed: () => _onPressed(current),
                          isSelected: menuStore.context.isSelection &&
                              store.isSelected(current),
                        );
                      },
                      childCount: store.displayableApps.length,
                    ),
                  ),
                );
              },
            ),
            MultiAnimatedBuilder(
              animations: [store],
              builder: (context, child) {
                return SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      if (store.fullyLoaded)
                        const AppVersionInfo()
                      else
                        const Padding(
                          padding: EdgeInsets.all(k12dp),
                          child: Center(child: AnimatedAppName()),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
