import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../pages/home_page.dart';
import '../setup.dart';
import '../stores/background_task_store.dart';
import '../stores/contextual_menu_store.dart';
import '../stores/localization_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
import '../utils/app_localization_strings.dart';
import '../utils/context_of.dart';
import '../utils/context_try_install_apk.dart';
import '../utils/package_bytes.dart';
import '../widgets/apk_file_menu_bottom_sheet.dart';
import '../widgets/apk_list_progress_stepper.dart';
import '../widgets/app_icon_button.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/background_task_list_contextual_menu.dart';
import '../widgets/current_selected_tree.dart';
import '../widgets/drag_select_scroll_notifier.dart';
import '../widgets/image_uri.dart';
import '../widgets/multi_animated_builder.dart';
import '../widgets/toast.dart';

class BackgroundTaskListScreen extends StatefulWidget {
  const BackgroundTaskListScreen({super.key});

  @override
  State<BackgroundTaskListScreen> createState() =>
      _BackgroundTaskListScreenState();
}

class _BackgroundTaskListScreenState extends State<BackgroundTaskListScreen> {
  @override
  Widget build(BuildContext context) {
    return const BackgroundTaskListScreenProvider(
      child: BackgroundTaskListScreenConsumer(),
    );
  }
}

class BackgroundTaskListScreenProvider extends StatefulWidget {
  const BackgroundTaskListScreenProvider({super.key, required this.child});

  final Widget child;

  @override
  State<BackgroundTaskListScreenProvider> createState() =>
      _BackgroundTaskListScreenProviderState();
}

class _BackgroundTaskListScreenProviderState
    extends State<BackgroundTaskListScreenProvider> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ContextualMenuStore>(
      create: (BuildContext context) => getIt<ContextualMenuStore>(),
      child: const BackgroundTaskListScreenConsumer(),
    );
  }
}

class BackgroundTaskListScreenConsumer extends StatefulWidget {
  const BackgroundTaskListScreenConsumer({super.key});

  @override
  State<BackgroundTaskListScreenConsumer> createState() =>
      _BackgroundTaskListScreenConsumerState();
}

class _BackgroundTaskListScreenConsumerState
    extends State<BackgroundTaskListScreenConsumer>
    with LocalizationStoreMixin, BackgroundTaskStoreMixin, SettingsStoreMixin {
  final Key _sliverListKey = const Key('app.backgroundtasklist');

  ContextualMenuStore get _menuStore => context.of<ContextualMenuStore>();

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    backgroundTaskStore.addListener(_selectionMenuHandler);
  }

  void _selectionMenuHandler() {
    if (backgroundTaskStore.selected.isEmpty) {
      if (_menuStore.menuContext.isSelection) _menuStore.popMenu();
    } else {
      _menuStore.pushSelectionMenu();
    }
  }

  @override
  void dispose() {
    backgroundTaskStore.removeListener(_selectionMenuHandler);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultContextualMenuPopHandler<ExtractApkBackgroundTask>(
      searchableStore: backgroundTaskStore,
      selectableStore: backgroundTaskStore,
      child: DragSelectScrollNotifier(
        isItemSelected: (String id) =>
            backgroundTaskStore.isSelected(itemId: id),
        enableSelect: _menuStore.menuContext.isSelection,
        scrollController: _scrollController,
        sliverLisKey: _sliverListKey,
        onChangeSelection: (List<String> itemIds, bool isSelecting) {
          _menuStore.pushSelectionMenu();

          if (isSelecting) {
            backgroundTaskStore.selectMany(itemIds: itemIds);
          } else {
            backgroundTaskStore.unselectMany(itemIds: itemIds);
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: <Widget>[
            BackgroundTaskListContextualMenu(
              onSearch: () {
                _menuStore.pushSearchMenu();
              },
            ),
            MultiAnimatedBuilder(
              animations: <Listenable>[settingsStore, backgroundTaskStore],
              builder: (BuildContext context, Widget? child) {
                return SliverList(
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      if (settingsStore.exportLocation != null &&
                          backgroundTaskStore.tasks.isNotEmpty)
                        const CurrentSelectedTree(),
                    ],
                  ),
                );
              },
            ),
            SliverPadding(
              padding: EdgeInsets.zero,
              sliver: MultiAnimatedBuilder(
                animations: <Listenable>[
                  backgroundTaskStore,
                  localizationStore,
                  settingsStore,
                ],
                builder: (BuildContext context, Widget? child) {
                  final List<ExtractApkBackgroundTask> tasks =
                      backgroundTaskStore.collection;

                  if (tasks.isEmpty) {
                    return const SliverFillRemaining(
                      child:
                          Center(child: StorageRequirementsProgressStepper()),
                    );
                  }

                  return SliverList(
                    key: _sliverListKey,
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return BackgroundTaskTile(
                          key: Key(tasks[index].id),
                          task: tasks[index],
                          isSelected: backgroundTaskStore.isSelected(
                            itemId: tasks[index].id,
                          ),
                        );
                      },
                      childCount: tasks.length,
                    ),
                  );
                },
              ),
            ),
            context.bottomSliverSpacer,
          ],
        ),
      ),
    );
  }
}

class BackgroundTaskTile extends StatefulWidget {
  const BackgroundTaskTile({
    super.key,
    required this.task,
    required this.isSelected,
  });

  final ExtractApkBackgroundTask task;
  final bool isSelected;

  @override
  State<BackgroundTaskTile> createState() => _BackgroundTaskTileState();
}

class _BackgroundTaskTileState extends State<BackgroundTaskTile>
    with LocalizationStoreMixin, BackgroundTaskStoreMixin, SettingsStoreMixin {
  String get formattedBytes => widget.task.sizeOrZero.formatBytes();

  DateTime? get _lastModified => widget.task.createdAt;

  DateFormat get dateFormatter => DateFormat.yMMMd(
        localizationStore.locale.toLanguageTag(),
      );

  String get formattedDate =>
      _lastModified != null ? dateFormatter.format(_lastModified!) : '';

  Widget? _buildTrailing() {
    if (widget.task.progress.status.isPending) {
      return AppIconButton(
        onTap: () => backgroundTaskStore.cancelBackgroundTask(widget.task),
        icon: Icon(AppIcons.x.data, size: AppIcons.x.size),
        tooltip: context.strings.cancelTask,
      );
    }

    if (!backgroundTaskStore.inSelectionMode) {
      return null;
    }

    return widget.isSelected
        ? Icon(
            AppIcons.checkboxSelected.data,
            size: kDefaultIconSize,
            color: context.primaryColor,
          )
        : Icon(
            AppIcons.checkboxUnselected.data,
            size: kDefaultIconSize,
            color: context.primaryColor,
          );
  }

  Widget _buildLeading() => PackageImageUri(uri: widget.task.apkIconUri);

  Future<void> _onBackgroundTaskTileTapped() async {
    if (backgroundTaskStore.inSelectionMode) {
      return backgroundTaskStore.toggleSelect(itemId: widget.task.id);
    }

    switch (widget.task.progress.status) {
      case TaskStatus.failed:
      case TaskStatus.partial:
      case TaskStatus.queued:
      case TaskStatus.running:
      case TaskStatus.initial:
        showToast(
          context,
          context.strings.extractionIsNotFinishedCanNotInstallYet,
        );
      case TaskStatus.deleted:
      case TaskStatus.deleteRequested:
        showToast(
          context,
          context.strings.tasksAreAlreadyBeingDeleted,
        );
      case TaskStatus.finished:
        await context.tryInstallPackage(
          backgroundTaskStore: backgroundTaskStore,
          taskId: widget.task.id,
          packageUri: widget.task.targetUri,
        );
    }
  }

  String get _taskSubtitle => '$formattedBytes, $formattedDate';

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      onTap: _onBackgroundTaskTileTapped,
      title: Text(widget.task.title ?? context.strings.loadingInfoEllipsis),
      subtitle: Text(_taskSubtitle),
      trailing: _buildTrailing(),
      onPopupMenuTapped: () async {
        if (widget.task.progress.status.isPending) return;

        await showModalBottomSheet<void>(
          isScrollControlled: true,
          context: context,
          useRootNavigator: true,
          barrierColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          builder: (_) => ApkFileMenuOptions(
            onDelete: () {
              backgroundTaskStore.deleteTask(taskId: widget.task.id);
            },
            packageId: widget.task.packageId,
            packageName: widget.task.packageName,
            packageInstallerUri: widget.task.targetUri,
            iconUri: widget.task.apkIconUri,
            subtitle: _taskSubtitle,
            title: widget.task.title ?? context.strings.notAvailable,
          ),
        );
      },
      selected: backgroundTaskStore.selected.isNotEmpty && widget.isSelected,
      inSelectionMode: backgroundTaskStore.inSelectionMode,
      leading: _buildLeading(),
    );
  }
}
