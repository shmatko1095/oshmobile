import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/text_styles.dart';

class AuthPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? footer;
  final Widget? preTitle;
  final PreferredSizeWidget? appBar;
  final TextAlign subtitleAlign;
  final double titleToSubtitleSpacing;
  final double subtitleToBodySpacing;
  final double bodyToFooterSpacing;

  const AuthPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.footer,
    this.preTitle,
    this.appBar,
    this.subtitleAlign = TextAlign.center,
    this.titleToSubtitleSpacing = 16,
    this.subtitleToBodySpacing = 24,
    this.bodyToFooterSpacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? AppBar(),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (preTitle != null) ...[
              preTitle!,
              const SizedBox(height: 28),
            ],
            Text(
              title,
              style: TextStyles.titleStyle,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: titleToSubtitleSpacing),
              Text(
                subtitle!,
                style: TextStyles.contentStyle,
                textAlign: subtitleAlign,
              ),
            ],
            SizedBox(height: subtitle != null ? subtitleToBodySpacing : 32),
            body,
            if (footer != null) ...[
              SizedBox(height: bodyToFooterSpacing),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
