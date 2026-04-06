import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class AuthPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? footer;
  final bool pinFooterToBottom;
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
    this.pinFooterToBottom = false,
    this.preTitle,
    this.appBar,
    this.subtitleAlign = TextAlign.center,
    this.titleToSubtitleSpacing = 16,
    this.subtitleToBodySpacing = 24,
    this.bodyToFooterSpacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    final bottomViewPadding = MediaQuery.viewPaddingOf(context).bottom;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleStyle = theme.textTheme.headlineMedium?.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.15,
          color: theme.colorScheme.onSurface,
        ) ??
        TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.15,
          color: theme.colorScheme.onSurface,
        );
    final subtitleStyle = theme.textTheme.bodyLarge?.copyWith(
          color:
              isDark ? AppPalette.textSecondary : AppPalette.lightTextSecondary,
          height: 1.4,
        ) ??
        TextStyle(
          fontSize: 16,
          color:
              isDark ? AppPalette.textSecondary : AppPalette.lightTextSecondary,
          height: 1.4,
        );
    final content = SingleChildScrollView(
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
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: titleToSubtitleSpacing),
            Text(
              subtitle!,
              style: subtitleStyle,
              textAlign: subtitleAlign,
            ),
          ],
          SizedBox(height: subtitle != null ? subtitleToBodySpacing : 32),
          body,
          if (!pinFooterToBottom && footer != null) ...[
            SizedBox(height: bodyToFooterSpacing),
            footer!,
          ],
        ],
      ),
    );

    return Scaffold(
      appBar: appBar ?? AppBar(),
      body: content,
      bottomNavigationBar: pinFooterToBottom && footer != null
          ? ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomViewPadding),
                child: footer!,
              ),
            )
          : null,
    );
  }
}
