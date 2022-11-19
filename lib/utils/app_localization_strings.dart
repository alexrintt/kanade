import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kanade/utils/lang_code_full_names.dart';

extension StringWithParams on String {
  String withArgs(List<String> args) {
    final paramRegExp = RegExp(r'{{.*}}');

    int index = 0;

    return replaceAllMapped(paramRegExp, (match) => args[index++]);
  }
}

extension AppLocalizationStrings on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this)!;
}

extension LocaleFullName on Locale {
  String get fullName => langCodeToFullName[languageCode]!;
}
