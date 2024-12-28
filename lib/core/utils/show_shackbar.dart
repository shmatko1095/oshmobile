import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';

class SnackBarUtils {
  static void showSuccess({
    required BuildContext context,
    required String content,
  }) {
    IconSnackBar.show(
      context,
      snackBarType: SnackBarType.success,
      label: content,
      maxLines: 2,
    );
  }

  static void showAlert({
    required BuildContext context,
    required String content,
  }) {
    IconSnackBar.show(
      context,
      snackBarType: SnackBarType.alert,
      label: content,
      maxLines: 2,
    );
  }

  static void showFail({
    required BuildContext context,
    required String content,
  }) {
    IconSnackBar.show(
      context,
      snackBarType: SnackBarType.fail,
      label: content,
      maxLines: 2,
    );
  }
}
