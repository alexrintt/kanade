import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';
import 'package:kanade/setup.dart';
import 'package:kanade/stores/settings.dart';
import 'package:kanade/utils/stringify_uri_location.dart';
import 'package:kanade/widgets/app_icon_button.dart';
import 'package:kanade/widgets/app_version_info.dart';
import 'package:pixelarticons/pixel.dart';

import '../stores/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

mixin SettingsStoreMixin<T extends StatefulWidget> on State<T> {
  SettingsStore? _settingsStore;
  SettingsStore get settingsStore => _settingsStore ??= getIt<SettingsStore>();

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _settingsStore = null; // Refresh store instance when updating the widget
  }
}

class _SettingsPageState extends State<SettingsPage>
    with SettingsStoreMixin, ThemeStoreMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            floating: true,
            pinned: false,
            titleSpacing: 0,
            leading: !Navigator.canPop(context)
                ? null
                : IconButton(
                    icon: const Icon(Pixel.arrowleft),
                    onPressed: () => Navigator.pop(context),
                  ),
            title: const Text('Settings'),
            actions: [
              AppIconButton(
                icon: const Icon(Pixel.reload),
                tooltip: 'Reset all preferences',
                onTap: () {
                  settingsStore.reset();
                  themeStore.reset();
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const ExportLocationSettingsTile(),
                const AppThemeSettingsTile(),
                const AppFontFamilySettingsTile(),
                const AppVersionInfo(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExportLocationSettingsTile extends StatefulWidget {
  const ExportLocationSettingsTile({Key? key}) : super(key: key);

  @override
  State<ExportLocationSettingsTile> createState() =>
      _ExportLocationSettingsTileState();
}

class _ExportLocationSettingsTileState extends State<ExportLocationSettingsTile>
    with SettingsStoreMixin {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: settingsStore.requestExportLocation,
      child: AnimatedBuilder(
        animation: settingsStore,
        builder: (context, child) {
          final exportLocation = stringifyTreeUri(
            settingsStore.exportLocation,
          );

          return ListTile(
            tileColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: k10dp,
            ),
            enableFeedback: true,
            leading: const Icon(Pixel.folder),
            title: const Text('Select export location'),
            subtitle: Text(exportLocation ?? 'Not defined'),
            trailing: const Icon(Pixel.chevronright),
          );
        },
      ),
    );
  }
}

class AppThemeSettingsTile extends StatefulWidget {
  const AppThemeSettingsTile({Key? key}) : super(key: key);

  @override
  State<AppThemeSettingsTile> createState() => _AppThemeSettingsTileState();
}

class _AppThemeSettingsTileState extends State<AppThemeSettingsTile>
    with ThemeStoreMixin {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const ChangeThemeDialog(),
        );
      },
      child: ListTile(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: k10dp,
        ),
        enableFeedback: true,
        leading: const Icon(Pixel.sun),
        title: const Text('Display theme'),
        subtitle: AnimatedBuilder(
          animation: themeStore,
          builder: (context, child) {
            return Text(themeStore.currentTheme.label);
          },
        ),
      ),
    );
  }
}

class ChangeThemeDialog extends StatefulWidget {
  const ChangeThemeDialog({Key? key}) : super(key: key);

  @override
  State<ChangeThemeDialog> createState() => _ChangeThemeDialogState();
}

class _ChangeThemeDialogState extends State<ChangeThemeDialog>
    with ThemeStoreMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeStore,
      builder: (context, child) {
        return SimpleDialog(
          backgroundColor: context.theme.backgroundColor,
          title: const Text('Theme'),
          children: [
            for (final theme in AppTheme.values)
              RadioListTile<AppTheme>(
                groupValue: themeStore.currentTheme,
                value: theme,
                title: Text(theme.label),
                onChanged: (value) => themeStore.setTheme(value!),
              ),
          ],
        );
      },
    );
  }
}

class AppFontFamilySettingsTile extends StatefulWidget {
  const AppFontFamilySettingsTile({Key? key}) : super(key: key);

  @override
  State<AppFontFamilySettingsTile> createState() =>
      _AppFontFamilySettingsTileState();
}

class _AppFontFamilySettingsTileState extends State<AppFontFamilySettingsTile>
    with ThemeStoreMixin {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const ChangeThemeFontFamilyDialog(),
        );
      },
      child: ListTile(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: k10dp,
        ),
        enableFeedback: true,
        leading: const Icon(Pixel.sortalpabetic),
        title: const Text('Font family'),
        subtitle: AnimatedBuilder(
          animation: themeStore,
          builder: (context, child) {
            return Text(themeStore.currentFontFamily.name);
          },
        ),
      ),
    );
  }
}

class ChangeThemeFontFamilyDialog extends StatefulWidget {
  const ChangeThemeFontFamilyDialog({Key? key}) : super(key: key);

  @override
  State<ChangeThemeFontFamilyDialog> createState() =>
      _ChangeThemeFontFamilyDialogState();
}

class _ChangeThemeFontFamilyDialogState
    extends State<ChangeThemeFontFamilyDialog> with ThemeStoreMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeStore,
      builder: (context, child) {
        return SimpleDialog(
          backgroundColor: context.theme.backgroundColor,
          title: const Text('Font'),
          children: [
            for (final fontFamily
                in AppFontFamily.values.where((e) => e.displayable))
              RadioListTile<AppFontFamily>(
                groupValue: themeStore.currentFontFamily,
                value: fontFamily,
                title: Text(fontFamily.name),
                onChanged: (value) => themeStore.setFontFamily(value!),
              ),
          ],
        );
      },
    );
  }
}
