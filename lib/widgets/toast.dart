import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kanade/constants/app_colors.dart';

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
