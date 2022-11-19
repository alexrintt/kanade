import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';
import 'package:kanade/stores/localization_store.dart';
import 'package:kanade/stores/settings.dart';
import 'package:kanade/utils/app_localization_strings.dart';
import 'package:kanade/utils/stringify_uri_location.dart';
import 'package:kanade/widgets/app_icon_button.dart';
import 'package:kanade/widgets/app_version_info.dart';
import 'package:kanade/widgets/horizontal_rule.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../stores/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SettingsStoreMixin, ThemeStoreMixin, LocalizationStoreMixin {
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
            title: Text(context.strings.settings),
            actions: [
              AppIconButton(
                icon: const Icon(Pixel.reload),
                tooltip: context.strings.resetAllPreferences,
                onTap: () {
                  settingsStore.reset();
                  themeStore.reset();
                  localizationStore.reset();
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                SettingsTileTitle(context.strings.export),
                const ExportLocationSettingsTile(),
                const HorizontalRule(),
                SettingsTileTitle(context.strings.display),
                const AppThemeSettingsTile(),
                const AppFontFamilySettingsTile(),
                const AppLocalizationSettingsTile(),
                const HorizontalRule(),
                const AppVersionInfo(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTileTitle extends StatelessWidget {
  final String title;

  const SettingsTileTitle(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: k12dp,
        vertical: k6dp,
      ).copyWith(top: k12dp),
      child: Text(
        title,
        style: TextStyle(
          color: context.theme.disabledColor,
        ),
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
            title: Text(context.strings.selectOutputFolder),
            subtitle: Text(exportLocation ?? context.strings.notDefined),
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
        title: Text(context.strings.theme),
        subtitle: AnimatedBuilder(
          animation: themeStore,
          builder: (context, child) {
            return Text(
              themeStore.currentTheme.getNameString(context.strings),
            );
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
          title: Text(context.strings.theme),
          children: [
            for (final theme in AppTheme.values)
              RadioListTile<AppTheme>(
                groupValue: themeStore.currentTheme,
                value: theme,
                title: Text(theme.getNameString(context.strings)),
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
        title: Text(context.strings.fontFamily),
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
          title: Text(context.strings.fontFamily),
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

class AppLocalizationSettingsTile extends StatefulWidget {
  const AppLocalizationSettingsTile({Key? key}) : super(key: key);

  @override
  State<AppLocalizationSettingsTile> createState() =>
      _AppLocalizationSettingsTileState();
}

class _AppLocalizationSettingsTileState
    extends State<AppLocalizationSettingsTile> with LocalizationStoreMixin {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const ChangeAppLocalizationDialog(),
        );
      },
      child: ListTile(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: k10dp,
        ),
        enableFeedback: true,
        leading: const Icon(Pixel.circle),
        title: Text(context.strings.language),
        subtitle: AnimatedBuilder(
          animation: localizationStore,
          builder: (context, child) {
            return Text(localizationStore.locale.fullName);
          },
        ),
      ),
    );
  }
}

class ChangeAppLocalizationDialog extends StatefulWidget {
  const ChangeAppLocalizationDialog({Key? key}) : super(key: key);

  @override
  State<ChangeAppLocalizationDialog> createState() =>
      _ChangeAppLocalizationDialogState();
}

class _ChangeAppLocalizationDialogState
    extends State<ChangeAppLocalizationDialog> with LocalizationStoreMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localizationStore,
      builder: (context, child) {
        return SimpleDialog(
          backgroundColor: context.theme.backgroundColor,
          title: Text(context.strings.language),
          children: [
            for (final localization in AppLocalizations.supportedLocales)
              RadioListTile<Locale>(
                groupValue: localizationStore.locale,
                value: localization,
                title: Text(localization.fullName),
                onChanged: (value) => localizationStore.setLocale(value!),
              ),
          ],
        );
      },
    );
  }
}
