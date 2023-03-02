import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../stores/background_task_store.dart';
import '../stores/contextual_menu_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_localization_strings.dart';
import '../utils/context_confirm.dart';
import '../utils/context_of.dart';
import 'app_icon_button.dart';
import 'sliver_app_top_bar.dart';

class BackgroundTaskListContextualMenu extends StatefulWidget {
  const BackgroundTaskListContextualMenu({
    super.key,
    this.onSearch,
  });

  final VoidCallback? onSearch;

  @override
  _BackgroundTaskListContextualMenuState createState() =>
      _BackgroundTaskListContextualMenuState();
}

/// We cannot split each [SliverAppBar] into multiple Widgets because we are rebuilding
/// only the [SliverAppBar] and not the entire [CustomScrollView]
class _BackgroundTaskListContextualMenuState
    extends State<BackgroundTaskListContextualMenu>
    with SettingsStoreMixin, BackgroundTaskStoreMixin {
  ContextualMenuStore get _menuStore => context.of<ContextualMenuStore>();

  Widget _buildSelectionMenu() {
    return SliverAppBar(
      title: AnimatedBuilder(
        animation: backgroundTaskStore,
        builder: (BuildContext context, Widget? child) {
          return Text(
            '${backgroundTaskStore.selected.length} ${context.strings.ofN} ${backgroundTaskStore.tasks.length}',
          );
        },
      ),
      pinned: !settingsStore
          .getBoolPreference(SettingsBoolPreference.hideAppBarOnScroll),
      floating: true,
      leading: IconButton(
        onPressed: () {
          _menuStore.popMenu();
          backgroundTaskStore.clearSelection();
        },
        icon: const Icon(Pixel.arrowleft),
      ),
      actions: <Widget>[
        AppIconButton(
          tooltip: 'Delete all selected',
          onTap: () async {
            final bool confirm = await showConfirmationModal(context: context);

            if (!confirm) return;

            await backgroundTaskStore.deleteSelectedBackgroundTasks();
          },
          icon: const Icon(Pixel.trash),
        ),
        AppIconButton(
          tooltip: context.strings.selectUnselectAll,
          onTap: backgroundTaskStore.toggleSelectAll,
          icon: AnimatedBuilder(
            animation: backgroundTaskStore,
            builder: (BuildContext context, Widget? child) {
              if (backgroundTaskStore.isAllSelected) {
                return Icon(Pixel.checkbox, color: context.colorScheme.primary);
              }

              return const Icon(Pixel.checkboxon);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchMenu() {
    return SliverAppBar(
      // backgroundColor: _appBarColorOverride,
      title: TextField(
        cursorColor: context.textTheme.bodyLarge!.color,
        autofocus: true,
        autocorrect: false,
        onChanged: backgroundTaskStore.search,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      ),
      pinned: !settingsStore
          .getBoolPreference(SettingsBoolPreference.hideAppBarOnScroll),
      floating: true,
      leading: AppIconButton(
        onTap: () {
          _menuStore.popMenu();
          backgroundTaskStore.disableSearch();
        },
        icon: const Icon(Pixel.arrowleft),
        tooltip: context.strings.exitSearch,
      ),
    );
  }

  Widget _buildNormalMenu() {
    return SliverAppTopBar(
      // backgroundColor: _appBarColorOverride,
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
