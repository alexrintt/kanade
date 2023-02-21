import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';

import '../stores/contextual_menu_store.dart';
import '../stores/device_apps.dart';
import '../stores/theme_store.dart';
import '../widgets/loading.dart';
import '../widgets/multi_animated_builder.dart';
import '../widgets/packages_list.dart';

class AppListScreen extends StatefulWidget {
  const AppListScreen({super.key});

  @override
  State<AppListScreen> createState() => _AppListScreenState();
}

class _AppListScreenState extends State<AppListScreen>
    with
        DeviceAppsStoreMixin<AppListScreen>,
        ContextualMenuStoreMixin<AppListScreen>,
        ThemeStoreMixin<AppListScreen> {
  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance
        .addPostFrameCallback((Duration timestamp) => _loadDevicePackages());
  }

  Future<void> _loadDevicePackages() async {
    await store.loadPackages();
  }

  Widget _buildHomeContent() {
    return MultiAnimatedBuilder(
      animations: <Listenable>[store, menuStore],
      builder: (BuildContext context, Widget? child) =>
          store.isLoading && store.apps.isEmpty
              ? const Loading()
              : const PackagesList(),
    );
  }

  Widget _loadingIndicatorBuilder(BuildContext context, Widget? child) {
    if (store.fullyLoaded) {
      return const SizedBox.shrink();
    }

    final bool isDeterminatedState =
        store.totalPackagesCount != null && store.loadedPackagesCount != null;

    double progress() {
      final double state =
          store.loadedPackagesCount! / store.totalPackagesCount!;

      return state.clamp(0, 1);
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      tween: Tween<double>(
        begin: 0,
        end: isDeterminatedState ? progress() : 0,
      ),
      builder: (BuildContext context, double value, _) =>
          LinearProgressIndicator(
        minHeight: k2dp,
        color: context.theme.primaryColor,
        backgroundColor: context.theme.cardColor,
        value: value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: _buildHomeContent()),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: SizedBox(
              height: k2dp,
              child: AnimatedBuilder(
                animation: store,
                builder: _loadingIndicatorBuilder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
