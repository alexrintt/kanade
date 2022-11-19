import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kanade/setup.dart';
import 'package:kanade/stores/key_value_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

mixin LocalizationStoreMixin<T extends StatefulWidget> on State<T> {
  LocalizationStore? _localizationStore;
  LocalizationStore get localizationStore =>
      _localizationStore ??= getIt<LocalizationStore>();
}

/// Store to manage the current active menu.
class LocalizationStore extends ChangeNotifier
    with KeyValueStorageConsumer<String, String?>, WidgetsBindingObserver {
  Locale? _locale;
  Locale get locale => _locale ?? defaultLocale;

  /// Returns the locale manually defined by the user (if any), [null] otherwise.
  Locale? get fixedLocale => _locale;

  static const _kLocaleLangCodeStorageKey = 'app.locale.langcode';
  static const _kLocaleCountryCodeStorageKey = 'app.locale.countrycode';

  String get _deviceLocaleName => Platform.localeName;
  List<String> get _deviceLangAndCountryCode => _deviceLocaleName.split('_');
  String get _deviceLangCode => _deviceLangAndCountryCode[0];

  // For now, we do not need country code...
  // String get _deviceCountryCode => _deviceLangAndCountryCode[1];
  Locale get deviceLocale => Locale(_deviceLangCode);

  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((e) => e.languageCode)
        .contains(locale.languageCode);
  }

  bool get isSystemLocalizationSupported {
    return isSupported(deviceLocale);
  }

  static const _kDefaultLangCode = 'en';

  @override
  void didChangeLocales(List<Locale>? locales) async {
    if (locales == null || locales.isEmpty) return;

    if (_locale != null) {
      // The user choose this language manually, so we will not follow the system.
      return;
    } else {
      // Notify it changed!
      notifyListeners();
    }
  }

  Locale get defaultLocale {
    if (isSystemLocalizationSupported) {
      return deviceLocale;
    }

    // Ensures 'en' is inside the [supportedLocales] array.
    return AppLocalizations.supportedLocales
        .firstWhere((e) => e.languageCode == _kDefaultLangCode);
  }

  Future<Locale?> get _cachedLocale async {
    final previousLangCode =
        await keyValueStorage.get(_kLocaleLangCodeStorageKey);

    // For now, we do not need country code...
    // final previousCountryCode =
    //     await keyValueStorage.get(_kLocaleCountryCodeStorageKey);

    if (previousLangCode != null) {
      return Locale(previousLangCode);
    }

    return null;
  }

  Future<void> load() async {
    final localeFromCache = await _cachedLocale;

    if (localeFromCache == null) {
      await reset();
    } else {
      await setLocale(localeFromCache);
    }

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> reset() async {
    await setLocale(null);
  }

  /// If [newLocale] is [null] then it will follow the system default language
  /// if supported, English otherwise.
  Future<void> setLocale(Locale? newLocale) async {
    // If the user changed it's language to a new
    // unsupported language, then just ignore it.
    if (newLocale != null && !isSupported(newLocale)) return;

    _locale = newLocale;

    keyValueStorage
      ..set(_kLocaleLangCodeStorageKey, newLocale?.languageCode)
      ..set(_kLocaleCountryCodeStorageKey, newLocale?.countryCode);

    notifyListeners();
  }
}
