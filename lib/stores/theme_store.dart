import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_shared_tools/constant/constant.dart';

import '../setup.dart';
import 'key_value_storage.dart';

enum AppTheme {
  darkLightsOut,
  darkDimmed,
  lightDefault,
  darkHacker,
  darkBlood,
  followSystem;

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

  static AppTheme parseCurrentThemeFromString(String appThemeString) {
    for (final AppTheme theme in AppTheme.values) {
      if (theme.toString() == appThemeString) {
        return theme;
      }
    }
    return kDefaultAppTheme;
  }

  static const AppTheme kDefaultAppTheme = AppTheme.followSystem;
}

extension BrightnessInverse on Brightness {
  Brightness get inverse => isDark ? Brightness.light : Brightness.dark;
  bool get isDark => this == Brightness.dark;
  bool get isLight => this == Brightness.light;
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

  static const String _kAppThemeStorageKey = 'app.theme';
  static const String _kAppFontFamilyStorageKey = 'app.fontfamily';

  KeyValueStorage<String, String?> get _keyValueStorage =>
      __keyValueStorage ??= getIt<KeyValueStorage<String, String?>>();
  KeyValueStorage<String, String?>? __keyValueStorage;

  Future<void> load() async {
    await _loadAppFontFamily();
    await _loadAppTheme();
  }

  Future<void> _loadAppFontFamily() async {
    final String? previousFontFamily =
        await _keyValueStorage.get(_kAppThemeStorageKey);

    if (previousFontFamily == null) {
      _currentFontFamily = AppFontFamily.defaultFont;
    } else {
      _currentFontFamily =
          AppFontFamily.parseCurrentFontFamilyFromString(previousFontFamily);
    }
  }

  Future<void> _loadAppTheme() async {
    addListener(() => setSystemUIOverlayStyle());

    final String? previousTheme =
        await _keyValueStorage.get(_kAppThemeStorageKey);

    if (previousTheme == null) {
      _currentTheme = AppTheme.kDefaultAppTheme;
    } else {
      _currentTheme = AppTheme.parseCurrentThemeFromString(previousTheme);
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
    const Color kCardColor = Color(0xFF25262E);
    const Color kBackgroundColor = Color(0xFF25262E);
    const Color kCanvasColor = Color(0xff282931);
    const Color kPrimaryColor = Color(0xffb8b9c5);
    const Color kSecondaryColor = kPrimaryColor;

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
    const Color kBackgroundColor = Color.fromARGB(255, 240, 240, 240);
    const Color kCardColor = kBackgroundColor;
    const Color kCanvasColor = Color(0xffEBEBEB);
    const MaterialColor kPrimaryColor = Colors.blue;
    const MaterialColor kSecondaryColor = Colors.blue;

    return createThemeData(
      canvasColor: kCanvasColor,
      backgroundColor: kBackgroundColor,
      cardColor: kCardColor,
      primaryColor: kPrimaryColor,
      secondaryColor: kSecondaryColor,
      textColor: Colors.black54,
      headlineColor: const Color(0xff111111),
      disabledColor: Colors.black12,
      base: ThemeData.light(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData _darkLightsOutThemeData() {
    const Color kBackgroundColor = Color.fromARGB(255, 8, 8, 8);
    const Color kCardColor = kBackgroundColor;
    const Color kCanvasColor = Color(0xff0B0B0B);
    const Color kPrimaryColor = Color(0xFFFFFFFF);
    const Color kSecondaryColor = Colors.white;

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
    const Color kBackgroundColor = Color.fromARGB(255, 8, 8, 8);
    const Color kCardColor = kBackgroundColor;
    const Color kCanvasColor = Color(0xff0B0B0B);
    const Color kPrimaryColor = Color(0xFF69F0AE);
    const MaterialColor kSecondaryColor = Colors.green;

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
    const Color kBackgroundColor = Color.fromARGB(255, 8, 8, 8);
    const Color kCardColor = kBackgroundColor;
    const Color kCanvasColor = Color(0xff0B0B0B);
    const Color kPrimaryColor = Color(0xFFFF5252);
    const Color kSecondaryColor = kPrimaryColor;

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
    await setTheme(AppTheme.kDefaultAppTheme);
    await setFontFamily(AppFontFamily.defaultFont);
  }
}

enum AppFontFamily {
  robotoMono('Roboto Mono', 0.9),
  forward('Forward', 1),
  zenKakuGothicAntique('Zen Kaku Gothic Antique', 1);

  const AppFontFamily(this.fontKey, this.preferableFontSizeDelta);

  static const AppFontFamily defaultFont = AppFontFamily.robotoMono;

  final double preferableFontSizeDelta;

  static AppFontFamily parseCurrentFontFamilyFromString(
    String fontFamilyString,
  ) {
    for (final AppFontFamily theme
        in AppFontFamily.values.where((AppFontFamily e) => e.displayable)) {
      if (theme.toString() == fontFamilyString) {
        return theme;
      }
    }
    return AppFontFamily.defaultFont;
  }

  /// Font family name decribed in the pubspec.yaml
  String getNameString(AppLocalizations localizations) {
    switch (this) {
      case AppFontFamily.forward:
        return 'Forward';
      case AppFontFamily.robotoMono:
        return 'Roboto Mono';
      case AppFontFamily.zenKakuGothicAntique:
        return 'Zen Kaku Gothic Antique';
    }
  }

  /// Font family name decribed in the pubspec.yaml
  final String? fontKey;
}

extension DisplayAppFontFamily on AppFontFamily {
  /// Wether or not this font can be used as main font family.
  bool get displayable {
    switch (this) {
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
  final String? fontFamilyName = fontFamily.fontKey;

  final TextTheme textTheme =
      base.textTheme.merge(Typography.material2021().black).apply(
            fontFamily: fontFamilyName,
            bodyColor: textColor,
          );

  return base.copyWith(
    bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
      elevation: 0,
      color: backgroundColor,
      surfaceTintColor: Colors.transparent,
    ),
    textButtonTheme: TextButtonThemeData(
      style: (base.textButtonTheme.style ?? const ButtonStyle()).copyWith(
        foregroundColor:
            MaterialStateProperty.resolveWith<Color?>((_) => textColor),
        surfaceTintColor: MaterialStateProperty.resolveWith<Color?>(
          (_) => Colors.transparent,
        ),
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.isNotEmpty) {
              return canvasColor;
            }
            return null;
          },
        ),
      ),
    ),
    scaffoldBackgroundColor: backgroundColor,
    disabledColor: disabledColor,
    textTheme: textTheme,
    primaryColor: primaryColor,
    dividerColor: disabledColor.withOpacity(.1),
    dividerTheme: base.dividerTheme.copyWith(
      color: disabledColor,
    ),
    appBarTheme: base.appBarTheme.copyWith(
      surfaceTintColor: Colors.transparent,
      backgroundColor: cardColor,
      elevation: 0,
      scrolledUnderElevation: 0,
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
    popupMenuTheme: base.popupMenuTheme.copyWith(elevation: 0),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: backgroundColor,
      elevation: 0,
      modalBackgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      modalElevation: 0,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(k40dp),
          topRight: Radius.circular(k40dp),
        ),
      ),
      // modalBarrierColor: Colors.black.withOpacity(.75),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: backgroundColor,
      elevation: 0,
      height: kToolbarHeight * 1.3,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      indicatorColor: primaryColor,
      labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>(
        (Set<MaterialState> states) {
          return textTheme.labelLarge!.copyWith(color: primaryColor);
        },
      ),
      iconTheme: MaterialStateProperty.resolveWith<IconThemeData?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return base.iconTheme.copyWith(color: backgroundColor);
          }
          return base.iconTheme.copyWith(color: primaryColor);
        },
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    dialogBackgroundColor: backgroundColor,
    canvasColor: canvasColor,
    cardColor: cardColor,
    tooltipTheme: base.tooltipTheme.copyWith(
      textStyle: TextStyle(color: backgroundColor),
      decoration: BoxDecoration(
        color: textColor,
        borderRadius: BorderRadius.circular(k1dp),
      ),
    ),
    colorScheme: base.colorScheme.copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
      outline: disabledColor,
    ),
    useMaterial3: true,
  );
}
