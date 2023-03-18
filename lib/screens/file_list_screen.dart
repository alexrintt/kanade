import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_storage/saf.dart';

import '../pages/home_page.dart';
import '../setup.dart';
import '../stores/contextual_menu_store.dart';
import '../stores/file_list_store.dart';
import '../stores/localization_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
import '../utils/context_of.dart';
import '../utils/mime_types.dart';
import '../utils/package_bytes.dart';
import '../widgets/apk_list_progress_stepper.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/current_selected_tree.dart';
import '../widgets/drag_select_scroll_notifier.dart';
import '../widgets/file_list_contextual_menu.dart';
import '../widgets/image_uri.dart';
import '../widgets/multi_animated_builder.dart';
import '../widgets/toast.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  @override
  Widget build(BuildContext context) {
    return const FileListScreenProvider(
      child: FileListScreenConsumer(),
    );
  }
}

class FileListScreenProvider extends StatefulWidget {
  const FileListScreenProvider({super.key, required this.child});

  final Widget child;

  @override
  State<FileListScreenProvider> createState() => _FileListScreenProviderState();
}

class _FileListScreenProviderState extends State<FileListScreenProvider> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ContextualMenuStore>(
      create: (BuildContext context) => getIt<ContextualMenuStore>(),
      child: const FileListScreenConsumer(),
    );
  }
}

class FileListScreenConsumer extends StatefulWidget {
  const FileListScreenConsumer({super.key});

  @override
  State<FileListScreenConsumer> createState() => _FileListScreenConsumerState();
}

class _FileListScreenConsumerState extends State<FileListScreenConsumer>
    with LocalizationStoreMixin, FileListStoreMixin, SettingsStoreMixin {
  final Key _sliverListKey = const Key('app.filelistview');

  ContextualMenuStore get _menuStore => context.of<ContextualMenuStore>();

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    fileListStore.addListener(_selectionMenuHandler);
  }

  void _selectionMenuHandler() {
    if (fileListStore.selected.isEmpty) {
      if (_menuStore.context.isSelection) _menuStore.popMenu();
    } else {
      _menuStore.pushSelectionMenu();
    }
  }

  @override
  void dispose() {
    fileListStore.removeListener(_selectionMenuHandler);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildFileListSliverUsingPredicate({
    required int Function(DocumentFile, DocumentFile) sortBy,
  }) {
    return SliverPadding(
      padding: EdgeInsets.zero,
      sliver: MultiAnimatedBuilder(
        animations: <Listenable>[
          fileListStore,
          localizationStore,
          settingsStore
        ],
        builder: (BuildContext context, Widget? child) {
          final List<DocumentFile> files = fileListStore.collection.toList()
            ..sort(sortBy);

          if (files.isEmpty) {
            return const SliverList(
              delegate: SliverChildListDelegate.fixed(<Widget>[]),
            );
          }

          return SliverList(
            key: _sliverListKey,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return DocumentFileTile(
                  key: Key(files[index].idOrUri),
                  file: files[index],
                  isSelected: fileListStore.isSelected(
                    itemId: files[index].id,
                  ),
                );
              },
              childCount: files.length,
            ),
          );
        },
      ),
    );
  }

  int _sortByNameAscAndFoldersFirst(DocumentFile a, DocumentFile z) {
    if (a.isDirectory ?? false) {
      if (!(z.isDirectory ?? false)) {
        return -1;
      }
    } else {
      if (z.isDirectory ?? false) {
        return 1;
      }
    }
    return (a.name ?? a.idOrUri)
        .toLowerCase()
        .compareTo((z.name ?? z.idOrUri).toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultContextualMenuPopHandler<DocumentFile>(
      searchableStore: fileListStore,
      selectableStore: fileListStore,
      child: RefreshIndicator(
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        onRefresh: fileListStore.reload,
        child: DragSelectScrollNotifier(
          isItemSelected: (String id) => fileListStore.isSelected(itemId: id),
          enableSelect: _menuStore.context.isSelection,
          scrollController: _scrollController,
          sliverLisKey: _sliverListKey,
          onChangeSelection: (List<String> itemIds, bool isSelecting) {
            _menuStore.pushSelectionMenu();

            if (isSelecting) {
              fileListStore.selectMany(itemIds: itemIds);
            } else {
              fileListStore.unselectMany(itemIds: itemIds);
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            slivers: <Widget>[
              FileListContextualMenu(
                onSearch: () {
                  _menuStore.pushSearchMenu();
                },
              ),
              MultiAnimatedBuilder(
                animations: <Listenable>[settingsStore, fileListStore],
                builder: (BuildContext context, Widget? child) {
                  final List<DocumentFile> files = fileListStore.collection;

                  if (files.isEmpty) {
                    return const SliverFillRemaining(
                      child:
                          Center(child: StorageRequirementsProgressStepper()),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        if (settingsStore.exportLocation != null)
                          const CurrentSelectedTree(),
                      ],
                    ),
                  );
                },
              ),
              // Show directories first.
              _buildFileListSliverUsingPredicate(
                sortBy: _sortByNameAscAndFoldersFirst,
              ),
              context.bottomSliverSpacer,
            ],
          ),
        ),
      ),
    );
  }
}

extension IdOrUri on DocumentFile {
  String get idOrUri => id ?? uri.toString();
}

class DocumentFileTile extends StatefulWidget {
  const DocumentFileTile({
    super.key,
    required this.file,
    required this.isSelected,
  });

  final DocumentFile file;
  final bool isSelected;

  @override
  State<DocumentFileTile> createState() => _DocumentFileTileState();
}

class _DocumentFileTileState extends State<DocumentFileTile>
    with LocalizationStoreMixin, FileListStoreMixin, SettingsStoreMixin {
  String get formattedBytes => (widget.file.size ?? 0).formatBytes();

  DateTime? get _lastModified => widget.file.lastModified;

  DateFormat get dateFormatter => DateFormat.yMMMd(
        localizationStore.locale.toLanguageTag(),
      );

  String get formattedDate =>
      _lastModified != null ? dateFormatter.format(_lastModified!) : '';

  void _toggleSelect() {
    fileListStore.toggleSelect(itemId: widget.file.id);
  }

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      onTap: () async {
        if (fileListStore.inSelectionMode) {
          _toggleSelect();
        } else {
          if (widget.file.isDirectory ?? false) {
            showToast(context, 'Opening a folder is not supported yet');
          } else {
            try {
              await widget.file.open();
            } on PlatformException {
              showToast(
                context,
                "There's no activity that can handle this file",
              );
            }
          }
        }
      },
      title: Text(widget.file.name ?? widget.file.uri.toString()),
      subtitle: Text('$formattedBytes, $formattedDate'),
      selected: fileListStore.selected.isNotEmpty && widget.isSelected,
      inSelectionMode: fileListStore.inSelectionMode,
      leading: DocumentFileThumbnail(file: widget.file),
    );
  }
}

class DocumentFileThumbnail extends StatefulWidget {
  const DocumentFileThumbnail({super.key, required this.file});

  final DocumentFile file;

  @override
  State<DocumentFileThumbnail> createState() => _DocumentFileThumbnailState();
}

class _DocumentFileThumbnailState extends State<DocumentFileThumbnail> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.file.type == kApkMimeType) {
      return ImageUri(
        uri: Uri.parse('${widget.file.uri}_icon'),
        loading: const Icon(AppIcons.apk, size: kDefaultIconSize),
        error: const Icon(AppIcons.apk, size: kDefaultIconSize),
      );
    }

    if (widget.file.isDirectory ?? false) {
      return const Icon(Icons.folder);
    }

    return ImageUri(
      fetchThumbnail: true,
      uri: widget.file.uri,
      loading: const Icon(AppIcons.apk, size: kDefaultIconSize),
      error: const Icon(AppIcons.apk, size: kDefaultIconSize),
    );
  }
}
