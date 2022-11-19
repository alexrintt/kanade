import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';

class HorizontalRule extends StatelessWidget {
  const HorizontalRule({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: k1dp,
      color: context.theme.dividerColor,
    );
  }
}
