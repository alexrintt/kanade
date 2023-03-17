import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/contextual_menu_store.dart';
import '../stores/file_list_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
import '../utils/app_localization_strings.dart';
import '../utils/context_confirm.dart';
import '../utils/context_of.dart';
import 'app_icon_button.dart';
import 'sliver_app_top_bar.dart';

class FileListContextualMenu extends StatefulWidget {
  const FileListContextualMenu({
    super.key,
    this.onSearch,
  });

  final VoidCallback? onSearch;

  @override
  _FileListContextualMenuState createState() => _FileListContextualMenuState();
}

/// We cannot split each [SliverAppBar] into multiple Widgets because we are rebuilding
/// only the [SliverAppBar] and not the entire [CustomScrollView]
class _FileListContextualMenuState extends State<FileListContextualMenu>
    with SettingsStoreMixin, FileListStoreMixin {
  ContextualMenuStore get _menuStore => context.of<ContextualMenuStore>();

  Widget _buildSelectionMenu() {
    return SliverAppBar(
      title: AnimatedBuilder(
        animation: fileListStore,
        builder: (BuildContext context, Widget? child) {
          return Text(
            '${fileListStore.selected.length} ${context.strings.ofN} ${fileListStore.collection.length}',
          );
        },
      ),
      pinned: !settingsStore
          .getBoolPreference(SettingsBoolPreference.hideAppBarOnScroll),
      floating: true,
      leading: IconButton(
        onPressed: () {
          _menuStore.popMenu();
          fileListStore.unselectAll();
        },
        icon: const Icon(
          AppIcons.arrowLeft,
          size: kDefaultIconSize,
        ),
      ),
      actions: <Widget>[
        AppIconButton(
          tooltip: 'Delete all selected',
          onTap: () async {
            final bool confirm = await showConfirmationModal(context: context);

            if (!confirm) return;

            await fileListStore.deleteSelectedFiles();
          },
          icon: const Icon(AppIcons.delete, size: kDefaultIconSize),
        ),
        AppIconButton(
          tooltip: context.strings.selectUnselectAll,
          onTap: fileListStore.toggleSelectAll,
          icon: AnimatedBuilder(
            animation: fileListStore,
            builder: (BuildContext context, Widget? child) {
              if (fileListStore.isAllSelected) {
                return Icon(
                  AppIcons.checkboxSelected,
                  size: kDefaultIconSize,
                  color: context.colorScheme.primary,
                );
              }

              return const Icon(
                AppIcons.checkboxUnselected,
                size: kDefaultIconSize,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchMenu() {
    return SliverAppBar(
      title: TextField(
        cursorColor: context.textTheme.bodyLarge!.color,
        autofocus: true,
        autocorrect: false,
        onChanged: fileListStore.search,
        style: const TextStyle(decorationThickness: 0),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
      pinned: !settingsStore
          .getBoolPreference(SettingsBoolPreference.hideAppBarOnScroll),
      floating: true,
      leading: AppIconButton(
        onTap: () {
          _menuStore.popMenu();
          fileListStore.disableSearch();
        },
        icon: const Icon(
          AppIcons.arrowLeft,
          size: kDefaultIconSize,
        ),
        tooltip: context.strings.exitSearch,
      ),
    );
  }

  Widget _buildNormalMenu() {
    return SliverAppTopBar(
      onSearch: widget.onSearch,
      pinned: !settingsStore
          .getBoolPreference(SettingsBoolPreference.hideAppBarOnScroll),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _menuStore,
      builder: (BuildContext context, Widget? child) {
        final MenuContext current = _menuStore.context;

        switch (current) {
          case MenuContext.selection:
            return _buildSelectionMenu();
          case MenuContext.search:
            return _buildSearchMenu();
          case MenuContext.normal:
            return _buildNormalMenu();
        }
      },
    );
  }
}
