import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_shared_tools/constant/constant.dart';

import '../setup.dart';
import '../widgets/no_glow_scroll_behavior.dart';
import 'key_value_storage.dart';

enum AppTheme {
  fullDark,
  darkDimmed,
  darkSimple,
  defaultLight,
  greenDark,
  redDark,
  followSystem;

  String getNameString(AppLocalizations strings) {
    switch (this) {
      case AppTheme.darkDimmed:
        return strings.darkDimmed;
      case AppTheme.darkSimple:
        return strings.darkSimple;
      case AppTheme.defaultLight:
        return strings.light;
      case AppTheme.followSystem:
        return strings.followTheSystem;
      case AppTheme.fullDark:
        return strings.fullDark;
      case AppTheme.greenDark:
        return strings.greenDark;
      case AppTheme.redDark:
        return strings.redDark;
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
  late OverscrollPhysics _currentOverscrollPhysics;

  static const String _kAppThemeStorageKey = 'app.theme';
  static const String _kAppFontFamilyStorageKey = 'app.fontfamily';
  static const String _kAppScrollBehaviorStorageKey = 'app.scrollbehavior';

  KeyValueStorage<String, String?> get _keyValueStorage =>
      __keyValueStorage ??= getIt<KeyValueStorage<String, String?>>();
  KeyValueStorage<String, String?>? __keyValueStorage;

  ScrollBehavior get scrollBehavior => _currentOverscrollPhysics.behavior;

  Future<void> load() async {
    await _loadAppFontFamily();
    await _loadAppTheme();
    await _loadOverscrollPhysics();
  }

  Future<void> _loadOverscrollPhysics() async {
    final String? previousOverscrollPhysics =
        await _keyValueStorage.get(_kAppScrollBehaviorStorageKey);

    if (previousOverscrollPhysics == null) {
      _currentOverscrollPhysics = OverscrollPhysics.defaultOverscrollPhysics;
    } else {
      _currentOverscrollPhysics =
          OverscrollPhysics.parseCurrentOverscrollPhysicsFromString(
        previousOverscrollPhysics,
      );
    }
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

    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
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
    const Color selectedTileColor = Color.fromARGB(255, 34, 35, 43);

    const Color kCanvasColor = Color(0xff282931);
    const Color kPrimaryColor = Color(0xffb8b9c5);
    const Color kSecondaryColor = Colors.black;

    return createThemeData(
      canvasColor: kCanvasColor,
      backgroundColor: kBackgroundColor,
      cardColor: kCardColor,
      primaryColor: kPrimaryColor,
      secondaryColor: kSecondaryColor,
      textColor: const Color(0xff84859B),
      headlineColor: Colors.white,
      disabledColor: const Color(0xff535466),
      selectedTileColor: selectedTileColor,
      base: ThemeData.dark(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData _defaultDarkThemeData() {
    const Color kCardColor = Color(0xFF313338);
    const Color kBackgroundColor = Color(0xFF2B2D31);
    const Color selectedTileColor = Color(0xff1E1F22);

    const Color kCanvasColor = Color(0xff313338);
    const Color kPrimaryColor = Color(0xffb8b9c5);
    const Color kSecondaryColor = Colors.black;

    return createThemeData(
      canvasColor: kCanvasColor,
      backgroundColor: kBackgroundColor,
      cardColor: kCardColor,
      primaryColor: kPrimaryColor,
      secondaryColor: kSecondaryColor,
      textColor: const Color(0xff84859B),
      headlineColor: Colors.white,
      disabledColor: const Color(0xff535466),
      selectedTileColor: selectedTileColor,
      base: ThemeData.dark(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData _defaultLightThemeData() {
    const Color kBackgroundColor = Color(0xffe8e8e8);
    const Color selectedTileColor = kBackgroundColor;
    const Color kCardColor = Color(0xfff7f2f9);
    const Color kCanvasColor = Color(0xfff7f2f9);
    const MaterialColor kPrimaryColor = MaterialColor(
      0xff262626,
      <int, Color>{
        50: Color(0xff262626),
        100: Color(0xff262626),
        200: Color(0xff262626),
        300: Color(0xff262626),
        400: Color(0xff262626),
        500: Color(0xff262626),
        600: Color(0xff262626),
        700: Color(0xff262626),
        800: Color(0xff262626),
        900: Color(0xff262626),
      },
    );
    const MaterialColor kSecondaryColor = Colors.blue;

    return createThemeData(
      canvasColor: kCanvasColor,
      backgroundColor: kBackgroundColor,
      cardColor: kCardColor,
      primaryColor: kPrimaryColor,
      secondaryColor: kSecondaryColor,
      textColor: Colors.black,
      headlineColor: const Color(0xff111111),
      selectedTileColor: selectedTileColor,
      disabledColor: Colors.black87,
      base: ThemeData.light(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData _fullDarkThemeData() {
    const Color kBackgroundColor = Color.fromARGB(255, 8, 8, 8);
    const Color kCardColor = kBackgroundColor;
    const Color kPrimaryColor = Color(0xFFFFFFFF);
    const Color kCanvasColor = Color.fromARGB(255, 14, 14, 14);
    const Color kSelectedTileColor = Color.fromARGB(255, 24, 24, 24);
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
      selectedTileColor: kSelectedTileColor,
      base: ThemeData.dark(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData _darkGreenThemeData() {
    const Color kBackgroundColor = Color.fromARGB(255, 8, 8, 8);
    const Color kCardColor = kBackgroundColor;
    const Color kPrimaryColor = Color(0xFF69F0AE);
    const Color kCanvasColor = Color.fromARGB(255, 10, 14, 10);
    const Color selectedTileColor = Color.fromARGB(255, 15, 25, 15);
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
      selectedTileColor: selectedTileColor,
      base: ThemeData.dark(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData _darkBloodThemeData() {
    const Color kBackgroundColor = Color.fromARGB(255, 8, 8, 8);
    const Color kCardColor = kBackgroundColor;
    const Color kPrimaryColor = Color(0xFFFF5252);
    const Color kCanvasColor = Color.fromARGB(255, 15, 10, 10);
    const Color selectedTileColor = Color.fromARGB(255, 25, 15, 15);
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
      selectedTileColor: selectedTileColor,
      base: ThemeData.dark(),
      fontFamily: _currentFontFamily,
    );
  }

  ThemeData get currentThemeData {
    switch (_currentTheme) {
      case AppTheme.darkDimmed:
        return _darkDimmedThemeData();
      case AppTheme.defaultLight:
        return _defaultLightThemeData();
      case AppTheme.fullDark:
        return _fullDarkThemeData();
      case AppTheme.greenDark:
        return _darkGreenThemeData();
      case AppTheme.redDark:
        return _darkBloodThemeData();
      case AppTheme.followSystem:
        return currentThemeBrightness == Brightness.dark
            ? _defaultDarkThemeData()
            : _defaultLightThemeData();
      case AppTheme.darkSimple:
        return _defaultDarkThemeData();
    }
  }

  Brightness get currentThemeBrightness {
    switch (_currentTheme) {
      case AppTheme.darkDimmed:
        return Brightness.dark;
      case AppTheme.defaultLight:
        return Brightness.light;
      case AppTheme.fullDark:
        return Brightness.dark;
      case AppTheme.greenDark:
        return Brightness.dark;
      case AppTheme.redDark:
        return Brightness.dark;
      case AppTheme.followSystem:
        return SchedulerBinding.instance.platformDispatcher.platformBrightness;
      case AppTheme.darkSimple:
        return Brightness.dark;
    }
  }

  AppTheme get currentTheme => _currentTheme;
  OverscrollPhysics get currentOverscrollPhysics => _currentOverscrollPhysics;
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

  Future<void> setOverscrollPhysics(OverscrollPhysics overscrollPhysics) async {
    await _keyValueStorage.set(
      _kAppScrollBehaviorStorageKey,
      '$overscrollPhysics',
    );
    _currentOverscrollPhysics = overscrollPhysics;
    notifyListeners();
  }

  Future<void> reset() async {
    await setTheme(AppTheme.kDefaultAppTheme);
    await setFontFamily(AppFontFamily.defaultFont);
    await setOverscrollPhysics(OverscrollPhysics.defaultOverscrollPhysics);
  }
}

enum AppFontFamily {
  robotoMono('Roboto Mono', 1, displayable: true),
  inconsolata('Inconsolata', 1, displayable: true),
  // This font is used in the logo only, so it is not displayable.
  forward('Forward', 1, displayable: false);

  const AppFontFamily(
    this.fontKey,
    this.preferableFontSizeDelta, {
    required this.displayable,
  });

  static const AppFontFamily defaultFont = AppFontFamily.inconsolata;

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
  final String fontKey;

  /// Wether or not this font can be used as main font family.
  final bool displayable;
}

enum OverscrollPhysics {
  none,
  bouncing,
  glow;

  static const OverscrollPhysics defaultOverscrollPhysics =
      OverscrollPhysics.none;

  /// Font family name decribed in the pubspec.yaml
  String getNameString(AppLocalizations strings) {
    switch (this) {
      case OverscrollPhysics.bouncing:
        return strings.bouncing;
      case OverscrollPhysics.glow:
        return strings.glow;
      case OverscrollPhysics.none:
        return strings.none;
    }
  }

  ScrollBehavior get behavior {
    switch (this) {
      case OverscrollPhysics.bouncing:
        return const BouncingScrollBehavior();
      case OverscrollPhysics.glow:
        return const GlowScrollBehavior();
      case OverscrollPhysics.none:
        return const NoneScrollBehavior();
    }
  }

  static OverscrollPhysics parseCurrentOverscrollPhysicsFromString(
    String overscrollPhysicsString,
  ) {
    for (final OverscrollPhysics overscrollPhysics
        in OverscrollPhysics.values) {
      if (overscrollPhysics.toString() == overscrollPhysicsString) {
        return overscrollPhysics;
      }
    }
    return OverscrollPhysics.defaultOverscrollPhysics;
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
  required Color selectedTileColor,
}) {
  final String fontFamilyName = fontFamily.fontKey;

  final TextTheme textTheme =
      base.textTheme.merge(Typography.material2021().black).apply(
            fontFamily: fontFamilyName,
            bodyColor: textColor,
          );

  return base.copyWith(
    bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
      elevation: 0,
      color: canvasColor,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: base.chipTheme.copyWith(
      // shadowColor: Colors.transparent,
      // surfaceTintColor: Colors.transparent,
      // elevation: ,
      backgroundColor: canvasColor,
      selectedColor: disabledColor,
      // elevation: 0.0,
      // pressElevation: 0.0,
      side: BorderSide.none,
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(k8dp),
        side: const BorderSide(
          color: Colors.transparent,
          width: 0.0,
        ),
      ),
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
      shadowColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 1,
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
      enableFeedback: true,
      selectedTileColor: selectedTileColor,
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
          topLeft: Radius.circular(k20dp),
          topRight: Radius.circular(k20dp),
        ),
      ),
      // modalBarrierColor: Colors.black.withOpacity(.75),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: canvasColor,
      elevation: 10,
      height: kToolbarHeight * 1.3,
      surfaceTintColor: Colors.transparent,
      shadowColor: backgroundColor,
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
    cardTheme: base.cardTheme.copyWith(
      shadowColor: backgroundColor,
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
