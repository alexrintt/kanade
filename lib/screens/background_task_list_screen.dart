import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_storage/saf.dart';

import '../pages/home_page.dart';
import '../setup.dart';
import '../stores/background_task_store.dart';
import '../stores/contextual_menu_store.dart';
import '../stores/indexed_collection_store.dart';
import '../stores/localization_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
import '../utils/context_confirm.dart';
import '../utils/context_of.dart';
import '../utils/package_bytes.dart';
import '../utils/share_file.dart';
import '../widgets/apk_file_popup_menu.dart';
import '../widgets/apk_list_progress_stepper.dart';
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
      if (_menuStore.context.isSelection) _menuStore.popMenu();
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
        enableSelect: _menuStore.context.isSelection,
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
                  settingsStore
                ],
                builder: (BuildContext context, Widget? child) {
                  final List<BackgroundTaskDisplayInfo> tasks =
                      backgroundTaskStore.displayBackgroundTasks;

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

  final BackgroundTaskDisplayInfo task;
  final bool isSelected;

  @override
  State<BackgroundTaskTile> createState() => _BackgroundTaskTileState();
}

class _BackgroundTaskTileState extends State<BackgroundTaskTile>
    with LocalizationStoreMixin, BackgroundTaskStoreMixin, SettingsStoreMixin {
  String get formattedBytes => widget.task.size.formatBytes();

  DateTime? get _lastModified => widget.task.createdAt;

  DateFormat get dateFormatter => DateFormat.yMMMd(
        localizationStore.locale.toLanguageTag(),
      );

  String get formattedDate =>
      _lastModified != null ? dateFormatter.format(_lastModified!) : '';

  Widget? _buildTrailing() {
    if (widget.task.progress.status.isPending) {
      return SizedBox(
        height: kToolbarHeight / 3,
        width: kToolbarHeight / 3,
        child: CircularProgressIndicator(
          backgroundColor: context.theme.disabledColor,
          strokeWidth: k1dp,
        ),
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
          'Not fully extracted yet, can not install right now',
        );
        break;
      case TaskStatus.finished:
        await _tryInstallApk();
        break;
    }
  }

  Future<void> _tryInstallApk() async {
    final PackageInstallationIntentResult result =
        await backgroundTaskStore.installPackage(
      installationId: widget.task.id,
      uri: widget.task.targetUri,
    );

    if (!result.ok) {
      if (mounted) {
        showToast(
          context,
          'Invalid apk, it is was probably deleted.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      onTap: _onBackgroundTaskTileTapped,
      title: Text(widget.task.title ?? 'Loading info...'),
      subtitle: Text('$formattedBytes, $formattedDate'),
      trailing: _buildTrailing(),
      onPopupMenuTapped: () async {
        final ApkFileTileAction? action = await showDialog<ApkFileTileAction>(
          context: context,
          builder: (_) => const ApkFilePopupMenu(),
        );
        if (action != null) {
          switch (action) {
            case ApkFileTileAction.delete:
              bool confirmed = false;

              if (mounted) {
                confirmed = await showConfirmationModal(context: context);
              }

              if (confirmed) {
                await backgroundTaskStore.deleteTask(taskId: widget.task.id);
              }

              break;
            case ApkFileTileAction.install:
              await _tryInstallApk();
              break;
            case ApkFileTileAction.share:
              await shareFile(uri: widget.task.targetUri);
              break;
            case ApkFileTileAction.open:
              if (widget.task.targetUri == null) {
                if (mounted) {
                  showToast(context, 'We could not find the target file');
                }
                return;
              }

              try {
                await openDocumentFile(
                  // This removes the "document" part
                  // which is used to identify the apk. And takes only the [tree]
                  // part which is used to (generally) identify the directory.
                  // This may not work on all devices.
                  widget.task.targetUri!.replace(
                    pathSegments: widget.task.targetUri!.pathSegments
                        .takeWhile((String value) => value != 'document')
                        .toList(),
                  ),
                );
              } on PlatformException catch (e) {
                if (mounted) {
                  showToast(
                    context,
                    'Could not find the file location, exception: $e',
                  );
                }
              }
              break;
          }
        }
      },
      selected: backgroundTaskStore.selected.isNotEmpty && widget.isSelected,
      inSelectionMode: backgroundTaskStore.inSelectionMode,
      leading: _buildLeading(),
    );
  }
}
