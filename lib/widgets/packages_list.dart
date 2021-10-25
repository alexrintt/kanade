import 'package:flutter/cupertino.dart';
import 'package:kanade/constants/app_colors.dart';
import 'package:kanade/constants/app_spacing.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';
import 'package:kanade/widgets/package_tile.dart';

import 'contextual_menu.dart';
import 'dotted_background.dart';

class PackagesList extends StatefulWidget {
  const PackagesList({Key? key}) : super(key: key);

  @override
  _PackagesListState createState() => _PackagesListState();
}

class _PackagesListState extends State<PackagesList>
    with DeviceAppsStoreConsumer, ContextualMenuStoreConsumer {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const ContextualMenu(),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final current = store.displayableApps[index];

                return PackageTile(current);
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
    );
  }
}
