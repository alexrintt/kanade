import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
      builder: (context, child) =>
          store.isLoading ? const Loading() : const PackagesList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildHomeContent(),
    );
  }
}
