import 'package:bbtml_new/main.dart';
import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart' show Toast, Fluttertoast;

void showToast(BuildContext context, String text) {
  final scaffold = ScaffoldMessenger.of(context);
  ScaffoldMessenger.of(navigatorKey.currentContext!).hideCurrentSnackBar();

  scaffold.showSnackBar(
    SnackBar(
      dismissDirection: DismissDirection.vertical,
      backgroundColor: Theme.of(context).appColors.textSecondary,
      duration: const Duration(seconds: 1),
      content: Text(text),
    ),
  );
}

void showFlutterToast(String msg) {
  Fluttertoast.showToast(
    toastLength: Toast.LENGTH_LONG,
    msg: msg,
    backgroundColor:
        Theme.of(navigatorKey.currentContext!).appColors.textSecondary,
    textColor: Theme.of(navigatorKey.currentContext!).appColors.background,
  );
}
