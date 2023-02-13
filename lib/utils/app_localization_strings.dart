import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'lang_code_full_names.dart';

extension StringWithParams on String {
  String withArgs(List<String> args) {
    final RegExp paramRegExp = RegExp('{{.*}}');

    int index = 0;

    return replaceAllMapped(paramRegExp, (Match match) => args[index++]);
  }
}

extension ContextStrings on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this)!;
}

extension LocaleFullName on Locale {
  String get fullName => langCodeToFullName[languageCode]!;
}
