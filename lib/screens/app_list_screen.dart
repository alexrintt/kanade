import 'dart:io';

import 'package:device_packages/device_packages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';
import 'package:provider/provider.dart';

import '../pages/home_page.dart';
import '../setup.dart';
import '../stores/contextual_menu_store.dart';
import '../stores/device_apps_store.dart';
import '../stores/settings_store.dart';
import '../stores/theme_store.dart';
import '../utils/app_localization_strings.dart';
import '../utils/context_confirm.dart';
import '../utils/context_of.dart';
import '../utils/context_show_apk_result_message.dart';
import '../widgets/animated_app_name.dart';
import '../widgets/animated_flip_counter.dart';
import '../widgets/app_list_contextual_menu.dart';
import '../widgets/device_app_tile.dart';
import '../widgets/drag_select_scroll_notifier.dart';
import '../widgets/loading.dart';
import '../widgets/looks_empty_here.dart';
import '../widgets/multi_animated_builder.dart';
import '../widgets/package_menu_bottom_sheet.dart';

class AppListScreen extends StatefulWidget {
  const AppListScreen({super.key});

  @override
  State<AppListScreen> createState() => _AppListScreenState();
}

class _AppListScreenState extends State<AppListScreen> {
  @override
  Widget build(BuildContext context) {
    return const AppListScreenProvider(
      child: AppListScreenConsumer(),
    );
  }
}

class AppListScreenProvider extends StatefulWidget {
  const AppListScreenProvider({super.key, required this.child});

  final Widget child;

  @override
  State<AppListScreenProvider> createState() => _AppListScreenProviderState();
}

class _AppListScreenProviderState extends State<AppListScreenProvider> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ContextualMenuStore>(
      create: (BuildContext context) => getIt<ContextualMenuStore>(),
      child: widget.child,
    );
  }
}

class AppListScreenConsumer extends StatefulWidget {
  const AppListScreenConsumer({super.key});

  @override
  State<AppListScreenConsumer> createState() => _AppListScreenConsumerState();
}

class _AppListScreenConsumerState extends State<AppListScreenConsumer>
    with DeviceAppsStoreMixin, ThemeStoreMixin<AppListScreenConsumer> {
  ContextualMenuStore get _menuStore => context.of<ContextualMenuStore>();

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
      animations: <Listenable>[store, _menuStore],
      builder: (BuildContext context, Widget? child) =>
          store.isLoading && store.apps.isEmpty
              ? const Loading()
              : const MainAppList(),
    );
  }

  Widget _loadingIndicatorBuilder(BuildContext context, Widget? child) {
    if (store.inProgress) {
      return LinearProgressIndicator(
        minHeight: k1dp,
        color: context.theme.primaryColor,
        backgroundColor: context.theme.cardColor,
      );
    }

    if (store.fullyLoaded) {
      return const SizedBox.shrink();
    }

    double progress() {
      final double state = store.percent;

      return state.clamp(0, 1);
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      tween: Tween<double>(
        begin: 0,
        end: progress(),
      ),
      builder: (BuildContext context, double value, _) =>
          LinearProgressIndicator(
        minHeight: k1dp,
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

class MainAppList extends StatefulWidget {
  const MainAppList({super.key});

  @override
  _MainAppListState createState() => _MainAppListState();
}

class _MainAppListState extends State<MainAppList>
    with DeviceAppsStoreMixin, SettingsStoreMixin {
  ContextualMenuStore get _menuStore => context.of<ContextualMenuStore>();

  final Key _kMainAppListViewKey = const Key('app.mainlistview');

  late ScrollController _scrollController;

  Future<void> _onPressed(PackageInfo package) async {
    if (_menuStore.context.isSelection) {
      store.toggleSelect(item: package);
    } else {
      if (settingsStore.shouldExtractWithSingleClick) {
        final SingleExtraction extraction =
            await store.extractApk(package: package);

        if (mounted) {
          context.showApkResultMessage(extraction.result);
        }
      } else {
        await _openModalBottomSheet(package);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _openModalBottomSheet(PackageInfo package) async {
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      builder: (_) => InstalledAppMenuOptions(
        iconBytes: package.icon,
        packageId: package.id,
        title: package.name ?? package.id ?? context.strings.unnamedPackage,
        subtitle: _generatePackageSubtitle(package),
        packageInstallerFile:
            package.installerPath != null ? File(package.installerPath!) : null,
        packageName: package.name,
      ),
    );
  }

  Widget _buildInstalledAppsFilterChip(
    String text,
    SettingsBoolPreference preference,
  ) {
    return Padding(
      padding: const EdgeInsets.all(k2dp),
      child: FilterChip(
        padding: const EdgeInsets.all(k2dp),
        label: Text(
          text,
          style: TextStyle(
            color: settingsStore.getBoolPreference(preference)
                ? context.scaffoldBackgroundColor
                : null,
          ),
        ),
        backgroundColor: context.dividerColor,
        selectedColor: context.primaryColor,
        onSelected: (bool value) async {
          final bool displaySystemApps = settingsStore
              .getBoolPreference(SettingsBoolPreference.displaySystemApps);
          final bool displayBuiltInApps = settingsStore
              .getBoolPreference(SettingsBoolPreference.displayBuiltInApps);
          final bool displayUserInstalledApps = settingsStore.getBoolPreference(
            SettingsBoolPreference.displayUserInstalledApps,
          );

          final bool hasRiskOfUnintentionalUnselect =
              store.hasRiskOfUnintentionalUnselect(
            displaySystemApps:
                preference == SettingsBoolPreference.displaySystemApps
                    ? value
                    : displaySystemApps,
            displayBuiltInApps:
                preference == SettingsBoolPreference.displayBuiltInApps
                    ? value
                    : displayBuiltInApps,
            displayUserInstalledApps:
                preference == SettingsBoolPreference.displayUserInstalledApps
                    ? value
                    : displayUserInstalledApps,
          );

          if (hasRiskOfUnintentionalUnselect) {
            final bool confirmed = await showConfirmationModal(
              context: context,
              force: true,
              message: context.strings.filterWillRemoveSomeSelectedItems,
            );

            if (!confirmed) return;
          }

          await settingsStore.setBoolPreference(preference, value: value);
        },
        selected: settingsStore.getBoolPreference(preference),
      ),
    );
  }

  String _generatePackageSubtitle(PackageInfo package) {
    final StringBuffer subtitle = StringBuffer();

    if (package.id != null) {
      subtitle.write(package.id);
    }

    if (package.versionName != null) {
      final String before = subtitle.isNotEmpty ? ' (' : '';
      final String after = subtitle.isNotEmpty ? ')' : '';
      subtitle.write(
        '$before${context.strings.version}: ${package.versionName}$after',
      );
    }

    if (subtitle.isEmpty && package.name != null) {
      subtitle.write(package.name);
    }

    if (subtitle.isNotEmpty) {
      return subtitle.toString();
    }

    return context.strings.unavailable;
  }

  Widget _buildFilterChips() {
    return SliverList(
      delegate: SliverChildListDelegate(
        <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: k5dp),
            child: Wrap(
              runAlignment: WrapAlignment.center,
              alignment: WrapAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(k2dp),
                  child: RawChip(
                    padding: const EdgeInsets.all(k2dp),
                    label: AnimatedCount(
                      duration: const Duration(milliseconds: 500),
                      count: store.collection.length,
                      curve: Curves.easeInOut,
                      textStyle: TextStyle(
                        color: context.primaryColor.withOpacity(.3),
                      ),
                    ),
                    backgroundColor: context.theme.canvasColor,
                  ),
                ),
                _buildInstalledAppsFilterChip(
                  context.strings.user,
                  SettingsBoolPreference.displayUserInstalledApps,
                ),
                _buildInstalledAppsFilterChip(
                  context.strings.builtIn,
                  SettingsBoolPreference.displayBuiltInApps,
                ),
                _buildInstalledAppsFilterChip(
                  context.strings.system,
                  SettingsBoolPreference.displaySystemApps,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultContextualMenuPopHandler<PackageInfo>(
      searchableStore: store,
      selectableStore: store,
      child: DragSelectScrollNotifier(
        scrollController: _scrollController,
        sliverLisKey: _kMainAppListViewKey,
        enableSelect: _menuStore.context.isSelection,
        isItemSelected: (String id) => store.isSelected(itemId: id),
        onChangeSelection: (List<String> selectedPackageIds, bool isSelecting) {
          if (selectedPackageIds.isNotEmpty) {
            _menuStore.pushSelectionMenu();

            if (isSelecting) {
              store.selectMany(itemIds: selectedPackageIds);
            } else {
              store.unselectMany(itemIds: selectedPackageIds);
            }
          }
        },
        child: MultiAnimatedBuilder(
          animations: <Listenable>[store, _menuStore, settingsStore],
          builder: (BuildContext context, Widget? child) => CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              AppListContextualMenu(onSearch: _menuStore.pushSearchMenu),
              _buildFilterChips(),
              MultiAnimatedBuilder(
                animations: <Listenable>[store, _menuStore],
                builder: (BuildContext context, Widget? child) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: k3dp),
                    sliver: SliverList(
                      key: _kMainAppListViewKey,
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final PackageInfo current = store.apps[index];

                          return DeviceAppTile(
                            key: Key(current.id!),
                            current,
                            subtitle: _generatePackageSubtitle(current),
                            showCheckbox: _menuStore.context.isSelection,
                            onTap: () => _onPressed(current),
                            isSelected: _menuStore.context.isSelection &&
                                store.isSelected(item: current),
                            onPopupMenuTapped:
                                settingsStore.shouldExtractWithSingleClick
                                    ? () => _openModalBottomSheet(current)
                                    : null,
                          );
                        },
                        childCount: store.apps.length,
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
                        if (store.collection.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(k8dp),
                            child: LooksEmptyHere(
                              message: store.isSearchMode
                                  ? context.strings.noResults
                                  : context
                                      .strings.trySelectingAtLeastOneFilter,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(k12dp)
                              .copyWith(bottom: k16dp),
                          child: const Center(child: AnimatedAppName()),
                        ),
                      ],
                    ),
                  );
                },
              ),
              context.bottomSliverSpacer,
            ],
          ),
        ),
      ),
    );
  }
}
