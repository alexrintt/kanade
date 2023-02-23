import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'loading_dots.dart';

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

Future<T?> showLoadingDialog<T>(BuildContext context, String message) async {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => AlertDialog(
      backgroundColor: context.theme.cardColor,
      contentPadding: const EdgeInsets.symmetric(vertical: k8dp),
      iconPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.all(k12dp),
      titlePadding: EdgeInsets.zero,
      buttonPadding: EdgeInsets.zero,
      actionsPadding: EdgeInsets.zero,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            height: k12dp,
            child: AspectRatio(
              aspectRatio: 2 / 1,
              child: DotLoadingIndicator(),
            ),
          ),
          const Padding(padding: EdgeInsets.all(k5dp)),
          Text(message),
        ],
      ),
    ),
  );
}
