import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../stores/localization_store.dart';
import '../stores/settings_store.dart';
import '../stores/theme_store.dart';
import '../utils/app_localization_strings.dart';
import '../utils/stringify_uri_location.dart';
import '../widgets/app_icon_button.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_version_info.dart';
import '../widgets/horizontal_rule.dart';

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
          AnimatedBuilder(
            animation: settingsStore,
            builder: (BuildContext context, Widget? child) {
              return SliverAppBar(
                automaticallyImplyLeading: false,
                floating: true,
                pinned: !settingsStore.getBoolPreference(
                  SettingsBoolPreference.hideAppBarOnScroll,
                ),
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
                title: Text(
                  context.strings.settings,
                  style: context.theme.appBarTheme.titleTextStyle!.copyWith(
                    color: context.theme.textTheme.labelSmall!.color,
                  ),
                ),
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
              );
            },
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
                const SettingsTileTitle('Behavior preferences'),
                AppBooleanPreferencesSettingsTile(
                  values: SettingsBoolPreference.filterBy(
                    category: SettingsBoolPreferenceCategory.behavior,
                  ),
                ),
                const HorizontalRule(),
                const SettingsTileTitle('Appearance preferences'),
                AppBooleanPreferencesSettingsTile(
                  values: SettingsBoolPreference.filterBy(
                    category: SettingsBoolPreferenceCategory.appearance,
                  ),
                ),
                const HorizontalRule(),
                const SettingsTileTitle('Credits'),
                const CreditsSettingsTile(),
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
        horizontal: k10dp,
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

          return AppListTile(
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
      child: AppListTile(
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
      child: AppListTile(
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
            return Text(
              themeStore.currentFontFamily.getNameString(context.strings),
            );
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
          // shape: const MaterialYouDialogShape(),
          backgroundColor: context.theme.colorScheme.background,
          title: Text(context.strings.fontFamily),
          children: <Widget>[
            for (final AppFontFamily fontFamily in AppFontFamily.values
                .where((AppFontFamily e) => e.displayable))
              RadioListTile<AppFontFamily>(
                groupValue: themeStore.currentFontFamily,
                value: fontFamily,
                title: Text(fontFamily.getNameString(context.strings)),
                onChanged: (AppFontFamily? value) =>
                    themeStore.setFontFamily(value!),
              ),
          ],
        );
      },
    );
  }
}

class CreditsSettingsTile extends StatefulWidget {
  const CreditsSettingsTile({super.key});

  @override
  State<CreditsSettingsTile> createState() => _CreditsSettingsTileState();
}

class _CreditsSettingsTileState extends State<CreditsSettingsTile> {
  final List<List<dynamic>> kLinks = <List<dynamic>>[
    <dynamic>[
      'Follow me on GitHub',
      (_) => launchUrlString(
            'https://github.com/alexrintt',
            mode: LaunchMode.externalApplication,
          ),
    ],
    <dynamic>[
      'GitHub donation',
      (_) => launchUrlString(
            'https://github.com/sponsors/alexrintt',
            mode: LaunchMode.externalApplication,
          ),
    ],
    <dynamic>[
      'Stripe donation',
      (_) => launchUrlString(
            'https://github.com/sponsors/alexrintt',
            mode: LaunchMode.externalApplication,
          ),
    ],
    <dynamic>[
      'Open source licenses',
      (BuildContext context) => showLicensePage(context: context),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final List<dynamic> tile in kLinks)
          InkWell(
            onTap: () => (tile.last as void Function(BuildContext))(context),
            child: AppListTile(
              tileColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: k10dp,
              ),
              enableFeedback: true,
              title: Text(tile.first as String),
            ),
          ),
      ],
    );
  }
}

class AppBooleanPreferencesSettingsTile extends StatefulWidget {
  const AppBooleanPreferencesSettingsTile({super.key, required this.values});

  final List<SettingsBoolPreference> values;

  @override
  State<AppBooleanPreferencesSettingsTile> createState() =>
      _AppBooleanPreferencesSettingsTileState();
}

class _AppBooleanPreferencesSettingsTileState
    extends State<AppBooleanPreferencesSettingsTile> with SettingsStoreMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsStore,
      builder: (BuildContext context, Widget? child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final SettingsBoolPreference preference in widget.values)
              InkWell(
                onTap: () => settingsStore.toggleBoolPreference(preference),
                child: AppListTile(
                  tileColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: k10dp,
                  ),
                  enableFeedback: true,
                  isThreeLine: true,
                  trailing: Switch(
                    trackColor: MaterialStateProperty.resolveWith(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return context.primaryColor;
                        }
                        return context.scaffoldBackgroundColor;
                      },
                    ),
                    overlayColor: MaterialStateProperty.resolveWith(
                      (Set<MaterialState> states) {
                        return context.theme.highlightColor;
                      },
                    ),
                    thumbColor: MaterialStateProperty.resolveWith(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          if (context.isDark) {
                            return context.theme.disabledColor;
                          }
                          return context.theme.dividerColor;
                        }

                        return context.isDark
                            ? context.theme.disabledColor
                            : context.theme.disabledColor.withOpacity(.2);
                      },
                    ),
                    splashRadius: k12dp,
                    thumbIcon: MaterialStateProperty.resolveWith(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Icon(Icons.check, color: context.primaryColor);
                        }
                        return null;
                      },
                    ),
                    activeColor: context.primaryColor,
                    value: settingsStore.getBoolPreference(preference),
                    onChanged: (bool value) => settingsStore
                        .setBoolPreference(preference, value: value),
                  ),
                  title: Text(preference.getNameString(context.strings)),
                  subtitle: Text(
                    preference.getDescriptionString(context.strings),
                    style: context.textTheme.labelLarge!.copyWith(
                      color: context.isDark
                          ? context.theme.disabledColor
                          : context.theme.disabledColor.withOpacity(.35),
                    ),
                  ),
                ),
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
      child: AppListTile(
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
          // shape: const MaterialYouDialogShape(),
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
