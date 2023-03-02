import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast(BuildContext context, String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: context.theme.textTheme.bodyLarge!.color,
    textColor: context.theme.colorScheme.background,
    fontSize: 14.0,
  );
}
