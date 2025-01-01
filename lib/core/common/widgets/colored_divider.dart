import 'package:flutter/material.dart';
import 'package:oshmobile/core/utils/ui_utils.dart';

class ColoredDivider extends StatelessWidget {
  final double? thickness;

  const ColoredDivider({super.key, this.thickness});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: getColorFromUiMode(context),
      thickness: thickness,
    );
  }
}
