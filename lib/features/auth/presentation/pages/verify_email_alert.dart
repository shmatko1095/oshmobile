part of 'signin_page.dart';

void _showVerifyDialog(BuildContext context, String email) {
  showCupertinoDialog(
    context: context,
    builder: (BuildContext context) {
      return VerifyEmailDialog(email: email);
    },
  );
}

class VerifyEmailDialog extends StatefulWidget {
  final String email;

  const VerifyEmailDialog({super.key, required this.email});

  @override
  State<VerifyEmailDialog> createState() => _VerifyEmailDialogState();
}

class _VerifyEmailDialogState extends State<VerifyEmailDialog> {
  bool _isEmailSent = false;

  void _sendEmail(String email) {
    context.read<AuthBloc>().add(AuthSendVerifyEmail(email: email));
    setState(() => _isEmailSent = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        );
    final contentStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color:
              isDark ? AppPalette.textSecondary : AppPalette.lightTextSecondary,
          height: 1.4,
        );
    final emailStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.primary,
    );

    return CupertinoAlertDialog(
      title: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              _isEmailSent
                  ? CupertinoIcons.check_mark_circled
                  : CupertinoIcons.mail,
              key: ValueKey<bool>(_isEmailSent),
              color: _isEmailSent
                  ? CupertinoColors.systemGreen
                  : AppPalette.accentPrimary,
              size: 56,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isEmailSent
                ? S.of(context).CheckYourEmail
                : S.of(context).VerifyYourEmail,
            style: titleStyle,
          ),
        ],
      ),
      content: Column(
        children: [
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              text: _isEmailSent
                  ? S.of(context).WeHaveSentVerificationEmailTo
                  : S.of(context).YourEmailIsNotVerifiedYet,
              style: contentStyle,
              children: _isEmailSent
                  ? [
                      TextSpan(
                        text: widget.email,
                        style: emailStyle,
                      ),
                      TextSpan(
                        text: S.of(context).PleaseCheckYourInbox,
                      ),
                    ]
                  : [],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        if (!_isEmailSent)
          CupertinoDialogAction(
            onPressed: () => _sendEmail(widget.email),
            child: Text(
              S.of(context).SendEmail,
              style: const TextStyle(color: AppPalette.accentPrimary),
            ),
          ),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            _isEmailSent ? S.of(context).OK : S.of(context).Cancel,
            style: _isEmailSent
                ? const TextStyle(color: AppPalette.accentPrimary)
                : const TextStyle(color: CupertinoColors.systemRed),
          ),
        ),
      ],
    );
  }
}
