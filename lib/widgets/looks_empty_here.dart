import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

const List<String> kDiscontentEmoticons = <String>[
  '┐(￣～￣)┌',
  '￣へ￣',
  '(ㆆ _ ㆆ)',
  '(╥﹏╥)',
  '(︶︹︺)',
  '(⌐■_■)',
  '(◡_◡)',
  '(︶︹︶)',
  '<(^_^)>',
  '	| (• ◡•)|',
  '(✿◠‿◠)',
  '(⌐⊙_⊙)',
];

String randomEmoticon([List<String> source = kDiscontentEmoticons]) =>
    source[Random().nextInt(source.length)];

class LooksEmptyHere extends StatelessWidget {
  const LooksEmptyHere({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          randomEmoticon(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.theme.disabledColor,
            fontSize: 22,
          ),
        ),
        if (message != null && message!.isNotEmpty)
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.theme.disabledColor,
              fontSize: 14,
            ),
          ),
      ],
    );
  }
}
