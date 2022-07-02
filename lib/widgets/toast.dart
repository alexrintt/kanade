import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kanade/constants/app_colors.dart';
import 'package:kanade/constants/app_spacing.dart';

void showToast(BuildContext context, String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: kBlack100,
    textColor: kWhite100,
    fontSize: 12.0,
  );
}

Future<T?> showLoadingDialog<T>(BuildContext context, String message) async {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: kCardColor,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: k12dp,
            width: k12dp,
            child: CircularProgressIndicator(
              color: kWhite100,
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
