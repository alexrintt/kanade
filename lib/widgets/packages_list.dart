import 'package:device_apps/device_apps.dart';
import 'package:flutter/cupertino.dart';
import 'package:kanade/constants/app_colors.dart';
import 'package:kanade/constants/app_spacing.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';
import 'package:kanade/widgets/package_tile.dart';
import 'package:kanade/widgets/toast.dart';

import 'contextual_menu.dart';
import 'dotted_background.dart';
import 'multi_animated_builder.dart';

class PackagesList extends StatefulWidget {
  const PackagesList({Key? key}) : super(key: key);

  @override
  _PackagesListState createState() => _PackagesListState();
}

class _PackagesListState extends State<PackagesList>
    with DeviceAppsStoreConsumer, ContextualMenuStoreConsumer {
  void _onLongPress(Application package) {
    menuStore.showSelectionMenu();
    store.toggleSelect(package);
  }

  void _onPressed(Application package) async {
    if (menuStore.context.isSelection) {
      store.toggleSelect(package);
    } else {
      final extraction = await store.extractApk(package);

      if (extraction.result.success) {
        showToast(context, 'Extracted to ${extraction.apk!.path}');
      } else if (extraction.result.permissionWasDenied) {
        showToast(context, 'Permission denied');
      } else if (extraction.result.restrictedPermission) {
        showToast(context, 'Permission restricted by Android');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiAnimatedBuilder(
      animations: [store, menuStore],
      builder: (context, child) => CustomScrollView(
        slivers: [
          const ContextualMenu(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 6),
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
                Opacity(
                  opacity: 0.1,
                  child: Image.asset('assets/images/bottom.png'),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: kBlack10,
                        offset: const Offset(k1dp, k1dp),
                        blurRadius: k1dp / 2,
                        spreadRadius: k1dp / 2,
                      ),
                    ],
                    color: kCardColor,
                  ),
                  child: DottedBackground(
                    color: kWhite10,
                    child: const SizedBox(
                      height: 10,
                      width: double.infinity,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
