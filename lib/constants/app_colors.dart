import 'package:flutter/material.dart';

import 'app_spacing.dart';

const kInConsolataFont = 'Inconsolata';
const kForwardFont = 'Forward';

final base = ThemeData.dark();

final appColors = base.copyWith(
  scaffoldBackgroundColor: const Color(0xFF1C1B22),
  textTheme: base.textTheme.apply(fontFamily: kInConsolataFont),
  appBarTheme:
      base.appBarTheme.copyWith(backgroundColor: const Color(0xFF25262E)),
  tooltipTheme: base.tooltipTheme.copyWith(
    textStyle: const TextStyle(color: kWhite100),
    decoration: BoxDecoration(
      color: const Color(0xFF33343A),
      borderRadius: BorderRadius.circular(k1dp),
      boxShadow: [
        BoxShadow(
          color: kBlack05,
          spreadRadius: k1dp,
          blurRadius: k1dp,
          offset: const Offset(k1dp, k1dp),
        ),
      ],
    ),
  ),
);

const kCardColor = Color(0xFF25262E);
const kBackgroundColor = Color(0xFF25262E);

final kBlack05 = Colors.black.withOpacity(.05);
final kBlack10 = Colors.black.withOpacity(.1);
final kBlack100 = Colors.black;

const kWhite100 = Colors.white;
final kWhite10 = Colors.white.withOpacity(.1);
final kWhite20 = Colors.white.withOpacity(.2);
final kWhite50 = Colors.white.withOpacity(.5);
final kWhite03 = Colors.white.withOpacity(.03);
final kWhite05 = Colors.white.withOpacity(.05);

final kAccent100 = Colors.blue;
