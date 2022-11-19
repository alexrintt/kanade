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
    with KeyValueStorageConsumer<String, String?> {
  late Locale locale;

  static const _kLocaleLangCodeStorageKey = 'app.locale.langcode';
  static const _kLocaleCountryCodeStorageKey = 'app.locale.countrycode';

  String get _deviceLocaleName => Platform.localeName;
  List<String> get _deviceLangAndCountryCode => _deviceLocaleName.split('_');
  String get _deviceLangCode => _deviceLangAndCountryCode[0];

  // For now, we do not need country code...
  // String get _deviceCountryCode => _deviceLangAndCountryCode[1];
  Locale get deviceLocale => Locale(_deviceLangCode);

  bool get isSystemLocalizationSupported {
    return AppLocalizations.supportedLocales
        .map((e) => e.languageCode)
        .contains(deviceLocale.languageCode);
  }

  static const _kDefaultLangCode = 'en';

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
  }

  Future<void> reset() async {
    await setLocale(defaultLocale);
  }

  Future<void> setLocale(Locale newLocale) async {
    locale = newLocale;

    keyValueStorage
      ..set(_kLocaleLangCodeStorageKey, newLocale.languageCode)
      ..set(_kLocaleCountryCodeStorageKey, newLocale.countryCode);

    notifyListeners();
  }
}
