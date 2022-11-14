import 'package:device_apps/device_apps.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';
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
        showLoadingDialog(context, 'Extracting Apk...');

        final extraction = await store.extractApk(package);

        if (!mounted) return;

        if (extraction.result.success) {
          showToast(context, 'Extracted to ${extraction.apk!.path}');
        } else if (extraction.result.permissionWasDenied) {
          showToast(context, 'Permission denied');
        } else if (extraction.result.restrictedPermission) {
          showToast(context, 'Permission restricted by Android');
        } else if (extraction.result.extractionNotAllowed) {
          showToast(
            context,
            'Operation not allowed, probably this is a protected package',
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
            SliverPadding(
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
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  const AppVersionInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
