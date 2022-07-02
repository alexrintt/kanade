import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:kanade/constants/app_colors.dart';
import 'package:kanade/constants/app_spacing.dart';
import 'package:kanade/stores/contextual_menu.dart';
import 'package:kanade/stores/device_apps.dart';
import 'package:kanade/widgets/loading.dart';
import 'package:kanade/widgets/multi_animated_builder.dart';
import 'package:kanade/widgets/packages_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with DeviceAppsStoreConsumer, ContextualMenuStoreConsumer {
  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance
        ?.addPostFrameCallback((timeStamp) => _loadDevicePackages());
  }

  void _loadDevicePackages() async {
    await store.loadPackages();
  }

  Widget _buildHomeContent() {
    return MultiAnimatedBuilder(
      animations: [store, menuStore],
      builder: (context, child) => store.isLoading && store.apps.isEmpty
          ? const Loading()
          : const PackagesList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildHomeContent()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SizedBox(
                height: k1dp,
                child: AnimatedBuilder(
                  animation: store,
                  builder: (context, child) {
                    if (store.fullyLoaded) {
                      return const SizedBox.shrink();
                    }

                    final isDeterminatedState =
                        store.totalPackagesCount != null ||
                            store.loadedPackagesCount != null;

                    double progress() {
                      final state = store.loadedPackagesCount! /
                          store.totalPackagesCount!;

                      return state.clamp(0, 1);
                    }

                    return LinearProgressIndicator(
                      minHeight: k2dp,
                      color: kWhite100,
                      backgroundColor: kWhite20,
                      value: isDeterminatedState ? progress() : null,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
