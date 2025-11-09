import 'package:bbtml_new/main.dart';
import 'package:flutter/material.dart';

void showToast(BuildContext context, String text) {
  final scaffold = ScaffoldMessenger.of(context);
  ScaffoldMessenger.of(navigatorKey.currentContext!).hideCurrentSnackBar();

  scaffold.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 1),
      content: Text(text),
      action: SnackBarAction(
          label: 'UNDO', onPressed: scaffold.hideCurrentSnackBar),
    ),
  );
}
