import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import '../stores/background_task_store.dart';
import '../stores/contextual_menu_store.dart';
import '../stores/settings_store.dart';
import '../utils/app_icons.dart';
import '../utils/app_localization_strings.dart';
import '../utils/context_confirm.dart';
import '../utils/context_of.dart';
import 'app_icon_button.dart';
import 'multi_animated_builder.dart';
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
          backgroundTaskStore.unselectAll();
        },
        icon: Icon(
          AppIcons.arrowLeft.data,
          size: kDefaultIconSize,
        ),
      ),
      actions: <Widget>[
        AppIconButton(
          tooltip: 'Delete all selected',
          onTap: () async {
            final bool confirm = await showConfirmationModal(context: context);

            if (!confirm) return;

            await backgroundTaskStore.deleteSelectedBackgroundTasks();
          },
          icon: Icon(
            AppIcons.delete.data,
            size: kDefaultIconSize,
            color: Colors.red,
          ),
        ),
        AppIconButton(
          tooltip: context.strings.selectUnselectAll,
          onTap: backgroundTaskStore.toggleSelectAll,
          icon: AnimatedBuilder(
            animation: backgroundTaskStore,
            builder: (BuildContext context, Widget? child) {
              if (backgroundTaskStore.isAllSelected) {
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
    return SliverAppBar(
      // backgroundColor: _appBarColorOverride,
      title: TextField(
        cursorColor: context.textTheme.bodyLarge!.color,
        autofocus: true,
        autocorrect: false,
        onChanged: backgroundTaskStore.search,
        style: const TextStyle(decorationThickness: 0),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
      pinned: !settingsStore
          .getBoolPreference(SettingsBoolPreference.hideAppBarOnScroll),
      floating: true,
      leading: AppIconButton(
        onTap: () {
          _menuStore.popMenu();
          backgroundTaskStore.disableSearch();
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
    return MultiAnimatedBuilder(
      animations: <Listenable>[backgroundTaskStore],
      builder: (_, __) {
        return SliverAppTopBar(
          onSearch: widget.onSearch,
          pinned: !settingsStore
              .getBoolPreference(SettingsBoolPreference.hideAppBarOnScroll),
          actions: <Widget>[
            if (backgroundTaskStore.collection.isNotEmpty)
              AppIconButton(
                icon: Icon(
                  backgroundTaskStore.idle
                      ? AppIcons.delete.data
                      : AppIcons.x.data,
                  size: kDefaultIconSize,
                  color: Colors.red,
                ),
                tooltip: 'Remove',
                onTap: () async {
                  if (backgroundTaskStore.idle) {
                    final bool confirmed = await showConfirmationModal(
                      context: context,
                      message:
                          'Do you want force a bulk delete on all these tasks?',
                    );

                    if (confirmed) {
                      await backgroundTaskStore.deleteAllBackgroundTasks();
                    }
                  } else {
                    final bool confirmed = await showConfirmationModal(
                      context: context,
                      message:
                          'Do you want force a bulk cancel on all these tasks?',
                    );

                    if (confirmed) {
                      await backgroundTaskStore.deleteAllBackgroundTasks();
                    }
                  }
                },
              ),
          ],
        );
      },
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
