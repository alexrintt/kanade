import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast(BuildContext context, String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: context.theme.textTheme.bodyText1!.color,
    textColor: context.theme.backgroundColor,
    fontSize: 12.0,
  );
}

Future<T?> showLoadingDialog<T>(BuildContext context, String message) async {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: context.theme.cardColor,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: k12dp,
            width: k12dp,
            child: CircularProgressIndicator(
              color: context.primaryColor,
              strokeWidth: k1dp,
            ),
          ),
          const Padding(padding: EdgeInsets.all(k5dp)),
          Text(message),
        ],
      ),
    ),
  );
}
