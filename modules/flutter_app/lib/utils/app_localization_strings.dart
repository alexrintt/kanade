import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'lang_code_full_names.dart';

extension ContextStrings on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this)!;
}

extension LocaleFullName on Locale {
  String get fullName => langCodeToFullName[languageCode]!;
}
