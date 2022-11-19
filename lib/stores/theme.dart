import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:kanade/setup.dart';
import 'package:kanade/stores/key_value_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum AppTheme {
  darkLightsOut,
  darkDimmed,
  lightDefault,
  darkHacker,
  darkBlood,
  followSystem,
}

extension AppThemeLabel on AppTheme {
  String getNameString(AppLocalizations strings) {
    switch (this) {
      case AppTheme.darkDimmed:
        return strings.darkDimmed;
      case AppTheme.lightDefault:
        return strings.light;
      case AppTheme.followSystem:
        return strings.followTheSystem;
      case AppTheme.darkLightsOut:
        return strings.darkLightsOut;
      case AppTheme.darkHacker:
        return strings.darkHacker;
      case AppTheme.darkBlood:
        return strings.darkBlood;
    }
  }
}

extension BrightnessInverse on Brightness {
  Brightness get inverse => isDark ? Brightness.light : Brightness.dark;
  bool get isDark => this == Brightness.dark;
  bool get isLight => this == Brightness.light;
}

AppTheme parseCurrentThemeFromString(String appThemeString) {
  for (final theme in AppTheme.values) {
    if (theme.toString() == appThemeString) {
      return theme;
    }
  }
  return defaultAppTheme();
}

AppTheme defaultAppTheme() {
  return AppTheme.followSystem;
}

AppFontFamily parseCurrentFontFamilyFromString(String fontFamilyString) {
  for (final theme in AppFontFamily.values.where((e) => e.displayable)) {
    if (theme.toString() == fontFamilyString) {
      return theme;
    }
  }
  return defaultAppFontFamily();
}

AppFontFamily defaultAppFontFamily() {
  return AppFontFamily.inconsolata;
}

mixin ThemeStoreMixin<T extends StatefulWidget> on State<T> {
  ThemeStore? _themeStore;
  ThemeStore get themeStore => _themeStore ??= getIt<ThemeStore>();

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _themeStore = null; // Refresh store instance when updating the widget
  }
}

class ThemeStore extends ChangeNotifier {
  late KeyValueStorage<String, String?> keyValueStorage;

  late AppTheme _currentTheme;
  late AppFontFamily _currentFontFamily;

  static const _kAppThemeStorageKey = 'app.theme';
  static const _kAppFontFamilyStorageKey = 'app.fontfamily';

  KeyValueStorage<String, String?> get _keyValueStorage =>
      __keyValueStorage ??= getIt<KeyValueStorage<String, String?>>();
  KeyValueStorage<String, String?>? __keyValueStorage;

  Future<void> load() async {
    await _loadAppFontFamily();
    await _loadAppTheme();
  }

  Future<void> _loadAppFontFamily() async {
    final previousFontFamily = await _keyValueStorage.get(_kAppThemeStorageKey);

    if (previousFontFamily == null) {
      _currentFontFamily = defaultAppFontFamily();
    } else {
      _currentFontFamily = parseCurrentFontFamilyFromString(previousFontFamily);
    }
  }

  Future<void> _loadAppTheme() async {
    addListener(() => setSystemUIOverlayStyle());

    final previousTheme = await _keyValueStorage.get(_kAppThemeStorageKey);

    if (previousTheme == null) {
      _currentTheme = defaultAppTheme();
    } else {
      _currentTheme = parseCurrentThemeFromString(previousTheme);
    }

    window.onPlatformBrightnessChanged = () {
      if (currentTheme == AppTheme.followSystem) {
        notifyListeners();
      }
    };

    setSystemUIOverlayStyle();
  }

  void setSystemUIOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: currentThemeData.brightness,
        statusBarIconBrightness: currentThemeData.brightness.inverse,
        systemNavigationBarIconBrightness: currentThemeData.brightness.inverse,
        systemNavigationBarColor: currentThemeData.cardColor,
      ),
    );
  }

  ThemeData _darkDimmedThemeData() {
    const kCardColor = Color(0xFF25262E);
    const kBackgroundColor = Color(0xFF25262E);
    const kCanvasColor = Color(0xff282931);
    const kPrimaryColor = Color(0xffb8b9c5);
    const kSecondaryColor = kPrimaryColor;

    return createThemeData(
      canvasColor: kCanvasColor,
      backgroundColor: kBackgroundColor,
      cardColor: kCardColor,
      primaryColor: kPrimaryColor,
      secondaryColor: kSecondaryColor,
      textColor: const Color(0xff84859B),
      headlineColor: Colors.white,
      disabledColor: const Color(0xff535466),
      base: ThemeData.dark(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData _lightDefaultThemeData() {
    const kBackgroundColor = Color.fromARGB(255, 240, 240, 240);
    const kCardColor = kBackgroundColor;
    const kCanvasColor = Color(0xffEBEBEB);
    const kPrimaryColor = Colors.blue;
    const kSecondaryColor = Colors.blue;

    return createThemeData(
      canvasColor: kCanvasColor,
      backgroundColor: kBackgroundColor,
      cardColor: kCardColor,
      primaryColor: kPrimaryColor,
      secondaryColor: kSecondaryColor,
      textColor: Colors.black87,
      headlineColor: const Color(0xff111111),
      disabledColor: Colors.black12,
      base: ThemeData.light(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData _darkLightsOutThemeData() {
    const kBackgroundColor = Color.fromARGB(255, 8, 8, 8);
    const kCardColor = kBackgroundColor;
    const kCanvasColor = Color(0xff0B0B0B);
    const kPrimaryColor = Color(0xFFFFFFFF);
    const kSecondaryColor = Colors.white;

    return createThemeData(
      canvasColor: kCanvasColor,
      backgroundColor: kBackgroundColor,
      cardColor: kCardColor,
      primaryColor: kPrimaryColor,
      secondaryColor: kSecondaryColor,
      textColor: Colors.white70,
      headlineColor: Colors.white,
      disabledColor: const Color.fromARGB(255, 78, 78, 78),
      base: ThemeData.dark(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData _darkHackerThemeData() {
    const kBackgroundColor = Color.fromARGB(255, 8, 8, 8);
    const kCardColor = kBackgroundColor;
    const kCanvasColor = Color(0xff0B0B0B);
    const kPrimaryColor = Color(0xFF69F0AE);
    const kSecondaryColor = Colors.green;

    return createThemeData(
      canvasColor: kCanvasColor,
      backgroundColor: kBackgroundColor,
      cardColor: kCardColor,
      primaryColor: kPrimaryColor,
      secondaryColor: kSecondaryColor,
      textColor: kPrimaryColor.withOpacity(0.7),
      headlineColor: kPrimaryColor,
      disabledColor: const Color.fromARGB(255, 44, 75, 59),
      base: ThemeData.dark(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData _darkBloodThemeData() {
    const kBackgroundColor = Color.fromARGB(255, 8, 8, 8);
    const kCardColor = kBackgroundColor;
    const kCanvasColor = Color(0xff0B0B0B);
    const kPrimaryColor = Color(0xFFFF5252);
    const kSecondaryColor = kPrimaryColor;

    return createThemeData(
      canvasColor: kCanvasColor,
      backgroundColor: kBackgroundColor,
      cardColor: kCardColor,
      primaryColor: kPrimaryColor,
      secondaryColor: kSecondaryColor,
      textColor: kPrimaryColor.withOpacity(0.7),
      headlineColor: kPrimaryColor,
      disabledColor: const Color.fromARGB(255, 87, 36, 36),
      base: ThemeData.dark(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData get currentThemeData {
    switch (_currentTheme) {
      case AppTheme.darkDimmed:
        return _darkDimmedThemeData();
      case AppTheme.lightDefault:
        return _lightDefaultThemeData();
      case AppTheme.darkLightsOut:
        return _darkLightsOutThemeData();
      case AppTheme.darkHacker:
        return _darkHackerThemeData();
      case AppTheme.darkBlood:
        return _darkBloodThemeData();
      case AppTheme.followSystem:
        return currentThemeBrightness == Brightness.dark
            ? _darkDimmedThemeData()
            : _lightDefaultThemeData();
    }
  }

  Brightness get currentThemeBrightness {
    switch (_currentTheme) {
      case AppTheme.darkDimmed:
        return Brightness.dark;
      case AppTheme.lightDefault:
        return Brightness.light;
      case AppTheme.darkLightsOut:
        return Brightness.dark;
      case AppTheme.darkHacker:
        return Brightness.dark;
      case AppTheme.darkBlood:
        return Brightness.dark;
      case AppTheme.followSystem:
        return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  AppTheme get currentTheme => _currentTheme;
  AppFontFamily get currentFontFamily => _currentFontFamily;

  Future<void> setTheme(AppTheme theme) async {
    await _keyValueStorage.set(_kAppThemeStorageKey, '$theme');
    _currentTheme = theme;
    notifyListeners();
  }

  Future<void> setFontFamily(AppFontFamily fontFamily) async {
    await _keyValueStorage.set(_kAppFontFamilyStorageKey, '$fontFamily');
    _currentFontFamily = fontFamily;
    notifyListeners();
  }

  Future<void> reset() async {
    await setTheme(defaultAppTheme());
    await setFontFamily(defaultAppFontFamily());
  }
}

enum AppFontFamily {
  inconsolata,
  robotoMono,
  forward,
  zenKakuGothicAntique,
}

extension AppFontFamilyName on AppFontFamily {
  /// Font family name decribed in the pubspec.yaml
  String get name {
    switch (this) {
      case AppFontFamily.inconsolata:
        return 'Inconsolata';
      case AppFontFamily.forward:
        return 'Forward';
      case AppFontFamily.robotoMono:
        return 'Roboto Mono';
      case AppFontFamily.zenKakuGothicAntique:
        return 'Zen Kaku Gothic Antique';
    }
  }
}

extension DisplayAppFontFamily on AppFontFamily {
  /// Wether or not this font can be used as main font family.
  bool get displayable {
    switch (this) {
      case AppFontFamily.inconsolata:
        return true;
      case AppFontFamily.forward:
        return false;
      case AppFontFamily.robotoMono:
        return true;
      case AppFontFamily.zenKakuGothicAntique:
        return true;
    }
  }
}

ThemeData createThemeData({
  required AppFontFamily fontFamily,
  required Color backgroundColor,
  required Color cardColor,
  required Color canvasColor,
  required ThemeData base,
  required Color secondaryColor,
  required Color primaryColor,
  required Color textColor,
  required Color disabledColor,
  required Color headlineColor,
}) {
  final fontFamilyName = fontFamily.name;

  final textTheme = base.textTheme.apply(
    fontFamily: fontFamilyName,
    bodyColor: textColor,
    fontSizeDelta: 0.0,
    fontSizeFactor: 1.0,
  );

  return base.copyWith(
    scaffoldBackgroundColor: backgroundColor,
    disabledColor: disabledColor,
    textTheme: textTheme,
    backgroundColor: backgroundColor,
    primaryColor: primaryColor,
    colorScheme: base.colorScheme.copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    dividerColor: disabledColor.withOpacity(.1),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: cardColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle:
          (base.appBarTheme.titleTextStyle ?? textTheme.displayLarge)!
              .copyWith(color: textColor, fontSize: k8dp),
      iconTheme: (base.appBarTheme.iconTheme ?? const IconThemeData.fallback())
          .copyWith(
        color: textColor,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: base.brightness.inverse,
        statusBarColor: Colors.transparent,
      ),
    ),
    listTileTheme: base.listTileTheme.copyWith(
      iconColor: textColor.withOpacity(0.5),
      textColor: textColor,
    ),
    splashColor: primaryColor.withOpacity(0.025),
    highlightColor: primaryColor.withOpacity(0.025),
    radioTheme: base.radioTheme.copyWith(
      fillColor: MaterialStateProperty.all(primaryColor),
    ),
    canvasColor: canvasColor,
    cardColor: cardColor,
    tooltipTheme: base.tooltipTheme.copyWith(
      textStyle: TextStyle(color: backgroundColor),
      decoration: BoxDecoration(
        color: textColor,
        borderRadius: BorderRadius.circular(k1dp),
      ),
    ),
  );
}
