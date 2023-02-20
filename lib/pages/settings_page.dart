import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';
import 'package:pixelarticons/pixel.dart';

import '../stores/localization_store.dart';
import '../stores/settings.dart';
import '../stores/theme.dart';
import '../utils/app_localization_strings.dart';
import '../utils/stringify_uri_location.dart';
import '../widgets/app_icon_button.dart';
import '../widgets/app_version_info.dart';
import '../widgets/horizontal_rule.dart';
import '../widgets/material_you_dialog_shape.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with
        SettingsStoreMixin,
        ThemeStoreMixin<SettingsPage>,
        LocalizationStoreMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            automaticallyImplyLeading: false,
            floating: true,
            titleSpacing: 0,
            leading: !Navigator.canPop(context)
                ? null
                : IconButton(
                    icon: Icon(
                      Pixel.arrowleft,
                      color: context.isDark ? null : context.primaryColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
            title: Text(context.strings.settings),
            actions: <Widget>[
              AppIconButton(
                icon: Icon(
                  Pixel.reload,
                  color: context.isDark ? null : context.primaryColor,
                ),
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
              <Widget>[
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
  const SettingsTileTitle(this.title, {super.key});

  final String title;

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
  const ExportLocationSettingsTile({super.key});

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
        builder: (BuildContext context, Widget? child) {
          final String? exportLocation = stringifyTreeUri(
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
  const AppThemeSettingsTile({super.key});

  @override
  State<AppThemeSettingsTile> createState() => _AppThemeSettingsTileState();
}

class _AppThemeSettingsTileState extends State<AppThemeSettingsTile>
    with ThemeStoreMixin<AppThemeSettingsTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) => const ChangeThemeDialog(),
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
          builder: (BuildContext context, Widget? child) {
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
  const ChangeThemeDialog({super.key});

  @override
  State<ChangeThemeDialog> createState() => _ChangeThemeDialogState();
}

class _ChangeThemeDialogState extends State<ChangeThemeDialog>
    with ThemeStoreMixin<ChangeThemeDialog> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeStore,
      builder: (BuildContext context, Widget? child) {
        return SimpleDialog(
          shape: const MaterialYouDialogShape(),
          backgroundColor: context.theme.colorScheme.background,
          title: Text(context.strings.theme),
          children: <Widget>[
            for (final AppTheme theme in AppTheme.values)
              RadioListTile<AppTheme>(
                groupValue: themeStore.currentTheme,
                value: theme,
                title: Text(theme.getNameString(context.strings)),
                onChanged: (AppTheme? value) => themeStore.setTheme(value!),
              ),
          ],
        );
      },
    );
  }
}

class AppFontFamilySettingsTile extends StatefulWidget {
  const AppFontFamilySettingsTile({super.key});

  @override
  State<AppFontFamilySettingsTile> createState() =>
      _AppFontFamilySettingsTileState();
}

class _AppFontFamilySettingsTileState extends State<AppFontFamilySettingsTile>
    with ThemeStoreMixin<AppFontFamilySettingsTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              const ChangeThemeFontFamilyDialog(),
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
          builder: (BuildContext context, Widget? child) {
            return Text(themeStore.currentFontFamily.name);
          },
        ),
      ),
    );
  }
}

class ChangeThemeFontFamilyDialog extends StatefulWidget {
  const ChangeThemeFontFamilyDialog({super.key});

  @override
  State<ChangeThemeFontFamilyDialog> createState() =>
      _ChangeThemeFontFamilyDialogState();
}

class _ChangeThemeFontFamilyDialogState
    extends State<ChangeThemeFontFamilyDialog>
    with ThemeStoreMixin<ChangeThemeFontFamilyDialog> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeStore,
      builder: (BuildContext context, Widget? child) {
        return SimpleDialog(
          shape: const MaterialYouDialogShape(),
          backgroundColor: context.theme.colorScheme.background,
          title: Text(context.strings.fontFamily),
          children: <Widget>[
            for (final AppFontFamily fontFamily in AppFontFamily.values
                .where((AppFontFamily e) => e.displayable))
              RadioListTile<AppFontFamily>(
                groupValue: themeStore.currentFontFamily,
                value: fontFamily,
                title: Text(fontFamily.name),
                onChanged: (AppFontFamily? value) =>
                    themeStore.setFontFamily(value!),
              ),
          ],
        );
      },
    );
  }
}

class AppLocalizationSettingsTile extends StatefulWidget {
  const AppLocalizationSettingsTile({super.key});

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
          builder: (BuildContext context) =>
              const ChangeAppLocalizationDialog(),
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
          builder: (BuildContext context, Widget? child) {
            if (localizationStore.fixedLocale == null) {
              String systemLanguageNotSupportedWarn = '';

              if (!localizationStore.isSystemLocalizationSupported) {
                systemLanguageNotSupportedWarn =
                    ', ${localizationStore.deviceLocale.fullName} ${context.strings.isNotSupportedYet}';
              }

              return Text(
                '${context.strings.followTheSystem} (${localizationStore.locale.fullName}$systemLanguageNotSupportedWarn)',
              );
            }
            return Text(localizationStore.fixedLocale!.fullName);
          },
        ),
      ),
    );
  }
}

class ChangeAppLocalizationDialog extends StatefulWidget {
  const ChangeAppLocalizationDialog({super.key});

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
      builder: (BuildContext context, Widget? child) {
        return SimpleDialog(
          shape: const MaterialYouDialogShape(),
          backgroundColor: context.theme.colorScheme.background,
          title: Text(context.strings.language),
          children: <Widget>[
            for (final Locale localization in AppLocalizations.supportedLocales)
              RadioListTile<Locale?>(
                groupValue: localizationStore.fixedLocale,
                value: localization,
                title: Text(localization.fullName),
                onChanged: (Locale? value) =>
                    localizationStore.setLocale(value),
              ),
            RadioListTile<Locale?>(
              groupValue: localizationStore.fixedLocale,
              value: null,
              title: Text(context.strings.followTheSystem),
              onChanged: (Locale? value) => localizationStore.setLocale(value),
            ),
          ],
        );
      },
    );
  }
}
