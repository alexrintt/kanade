import 'dart:async';

import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/contextual_menu_store.dart';
import '../stores/device_apps.dart';
import '../utils/app_localization_strings.dart';
import 'animated_app_name.dart';
import 'app_version_info.dart';
import 'contextual_menu.dart';
import 'multi_animated_builder.dart';
import 'package_tile.dart';
import 'toast.dart';

class PackagesList extends StatefulWidget {
  const PackagesList({super.key});

  @override
  _PackagesListState createState() => _PackagesListState();
}

class _PackagesListState extends State<PackagesList>
    with
        DeviceAppsStoreMixin<PackagesList>,
        ContextualMenuStoreMixin<PackagesList> {
  void _onLongPress(PackageInfo package) {
    menuStore.pushSelectionMenu();
    store.toggleSelect(package);
  }

  Future<void> _onPressed(PackageInfo package) async {
    if (menuStore.context.isSelection) {
      store.toggleSelect(package);
    } else {
      try {
        unawaited(showLoadingDialog(context, context.strings.extractingApks));

        final ApkExtraction extraction = await store.extractApk(package);

        if (!mounted) return;

        switch (extraction.result) {
          case Result.extracted:
            showToast(
              context,
              '${context.strings.extractedTo} ${extraction.apk!.path}',
            );
            break;
          case Result.permissionDenied:
            showToast(context, context.strings.permissionDenied);
            break;
          case Result.permissionRestricted:
            showToast(context, context.strings.permissionRestrictedByAndroid);
            break;
          case Result.notAllowed:
            showToast(
              context,
              context.strings.operationNotAllowedMayBeProtectedPackage,
            );
            break;
          case Result.notFound:
            showToast(
              context,
              // TODO: Missing translation.
              'Could not extract, this apk was probably uninstalled because we did not found it is apk file',
            );
            break;
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
        animations: <Listenable>[store, menuStore],
        builder: (BuildContext context, Widget? child) => CustomScrollView(
          slivers: <Widget>[
            ContextualMenu(onSearch: menuStore.pushSearchMenu),
            MultiAnimatedBuilder(
              animations: <Listenable>[store, menuStore],
              builder: (BuildContext context, Widget? child) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: k3dp),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final PackageInfo current =
                            store.displayableApps[index];

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
              animations: <Listenable>[store],
              builder: (BuildContext context, Widget? child) {
                return SliverList(
                  delegate: SliverChildListDelegate(
                    <Widget>[
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
