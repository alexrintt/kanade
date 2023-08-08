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

class LooksEmptyHere extends StatefulWidget {
  const LooksEmptyHere({super.key, this.message});

  final String? message;

  @override
  State<LooksEmptyHere> createState() => _LooksEmptyHereState();
}

class _LooksEmptyHereState extends State<LooksEmptyHere> {
  late String _emoji;

  @override
  void initState() {
    super.initState();
    _emoji = randomEmoticon();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          _emoji,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.theme.disabledColor,
            fontSize: 22,
          ),
        ),
        if (widget.message != null && widget.message!.isNotEmpty)
          Text(
            widget.message!,
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
