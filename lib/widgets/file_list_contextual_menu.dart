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
import 'sliver_app_bar_translucent.dart';
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
    return SliverAppBarTranslucent(
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
      leading: IconButton(
        onPressed: () {
          _menuStore.popMenu();
          fileListStore.unselectAll();
        },
        icon: Icon(
          AppIcons.arrowLeft.data,
          size: kDefaultIconSize,
        ),
      ),
      actions: <Widget>[
        AppIconButton(
          tooltip: context.strings.deleteAllSelected,
          onTap: () async {
            final bool confirm = await showConfirmationModal(context: context);

            if (!confirm) return;

            await fileListStore.deleteSelectedFiles();
          },
          icon: Icon(
            AppIcons.delete.data,
            size: kDefaultIconSize,
            color: Colors.red,
          ),
        ),
        AppIconButton(
          tooltip: context.strings.selectUnselectAll,
          onTap: fileListStore.toggleSelectAll,
          icon: AnimatedBuilder(
            animation: fileListStore,
            builder: (BuildContext context, Widget? child) {
              if (fileListStore.isAllSelected) {
                return Icon(
                  AppIcons.checkboxSelected.data,
                  size: kDefaultIconSize,
                  color: context.colorScheme.primary,
                );
              }

              return Icon(
                AppIcons.checkboxUnselected.data,
                size: kDefaultIconSize,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchMenu() {
    return SliverAppBarTranslucent(
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
      leading: AppIconButton(
        onTap: () {
          _menuStore.popMenu();
          fileListStore.disableSearch();
        },
        icon: Icon(
          AppIcons.arrowLeft.data,
          size: kDefaultIconSize,
        ),
        tooltip: context.strings.exitSearch,
      ),
    );
  }

  Widget _buildNormalMenu() {
    return SliverAppBarGlobal(
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
        final MenuContext current = _menuStore.menuContext;

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
