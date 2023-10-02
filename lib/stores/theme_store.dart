import 'dart:ui';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../setup.dart';
import '../widgets/no_glow_scroll_behavior.dart';
import 'key_value_storage.dart';

enum AppTheme {
  defaultDark,
  defaultLight,
  followSystem;

  String getNameString(AppLocalizations strings) {
    switch (this) {
      case AppTheme.defaultDark:
        return strings.dark;
      case AppTheme.defaultLight:
        return strings.light;
      case AppTheme.followSystem:
        return strings.followTheSystem;
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

  late (ColorScheme?, ColorScheme?) _platformAdaptiveColorPalettes;

  Future<void> load() async {
    await _loadOSPalette();
    await _loadAppFontFamily();
    await _loadAppTheme();
    await _loadOverscrollPhysics();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<(ColorScheme?, ColorScheme?)>
      _getPlatformDynamicColorPalettes() async {
    try {
      final CorePalette? corePalette =
          await DynamicColorPlugin.getCorePalette();

      if (corePalette != null) {
        debugPrint('dynamic_color: Core palette detected.');

        return (
          corePalette.toColorScheme(),
          corePalette.toColorScheme(brightness: Brightness.dark)
        );
      }
    } on PlatformException {
      debugPrint('dynamic_color: Failed to obtain core palette.');
    }

    try {
      final Color? accentColor = await DynamicColorPlugin.getAccentColor();

      if (accentColor != null) {
        debugPrint('dynamic_color: Accent color detected.');

        return (
          ColorScheme.fromSeed(
            seedColor: accentColor,
            // brightness: Brightness.light,
          ),
          ColorScheme.fromSeed(
            seedColor: accentColor,
            brightness: Brightness.dark,
          ),
        );
      }
    } on PlatformException {
      debugPrint('dynamic_color: Failed to obtain accent color.');
    }

    debugPrint('dynamic_color: Dynamic color not detected on this device.');

    return (null, null);
  }

  Future<void> _loadOSPalette() async {
    final (ColorScheme?, ColorScheme?) p =
        await _getPlatformDynamicColorPalettes();
    _platformAdaptiveColorPalettes = p;
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

  ThemeData _darkDefaultThemeData() {
    final (ColorScheme? _, ColorScheme? darkAdaptivePalette) =
        _platformAdaptiveColorPalettes;

    return createThemeData(
      base: ThemeData.from(
        useMaterial3: true,
        colorScheme: darkAdaptivePalette ??
            ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
      ),
    );
  }

  ThemeData _darkFallbackThemeData() {
    return _darkDefaultThemeData();
  }

  ThemeData _lightDefaultThemeData() {
    final (ColorScheme? lightAdaptivePalette, ColorScheme? _) =
        _platformAdaptiveColorPalettes;

    return createThemeData(
      base: ThemeData.from(
        useMaterial3: true,
        colorScheme: lightAdaptivePalette ??
            ColorScheme.fromSeed(
              seedColor: Colors.blue,
              // brightness: Brightness.light,
            ),
      ),
    );
  }

  ThemeData _lightFallbackThemeData() {
    return _lightDefaultThemeData();
  }

  ThemeData get currentThemeData {
    switch (_currentTheme) {
      case AppTheme.defaultDark:
        return _darkDefaultThemeData();
      case AppTheme.defaultLight:
        return _lightFallbackThemeData();

      case AppTheme.followSystem:
        return currentThemeBrightness == Brightness.dark
            ? _darkFallbackThemeData()
            : _lightFallbackThemeData();
    }
  }

  Brightness get currentThemeBrightness {
    switch (_currentTheme) {
      case AppTheme.defaultDark:
        return Brightness.dark;
      case AppTheme.defaultLight:
        return Brightness.light;
      case AppTheme.followSystem:
        return SchedulerBinding.instance.platformDispatcher.platformBrightness;
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
  robotoMono('Roboto Mono', 1, displayable: false),
  inconsolata('Inconsolata', 1, displayable: false),
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
  required ThemeData base,
}) {
  return base.copyWith(useMaterial3: true);
}
