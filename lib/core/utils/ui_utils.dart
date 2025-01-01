import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

bool isDarkUi(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color getColorFromUiMode(context) => isDarkUi(context)
    ? AppPalette.activeTextFieldColorDark
    : AppPalette.activeTextFieldColorLight;
