import 'package:flutter/material.dart';

bool isDarkUi(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
