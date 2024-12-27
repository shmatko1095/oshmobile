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

class _VerifyEmailDialogState extends State<VerifyEmailDialog>
    with SingleTickerProviderStateMixin {
  final TextStyle _titleStyle = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  final TextStyle _contentStyle = const TextStyle(
    fontSize: 16,
    color: CupertinoColors.systemGrey,
  );
  final TextStyle _emailStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    color: CupertinoColors.activeBlue,
  );

  bool isEmailSent = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _sendEmail(String email) {
    context.read<AuthBloc>().add(AuthSendVerifyEmail(email: email));
    _animationController.forward(from: 0.0);
    setState(() => isEmailSent = true);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Column(
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 800),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              isEmailSent
                  ? CupertinoIcons.check_mark_circled
                  : CupertinoIcons.mail,
              key: ValueKey<bool>(isEmailSent),
              color: isEmailSent
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.activeBlue,
              size: 60.0,
            ),
          ),
          SizedBox(height: 10),
          Text(
            isEmailSent
                ? S.of(context).CheckYourEmail
                : S.of(context).VerifyYourEmail,
            style: _titleStyle,
          ),
        ],
      ),
      content: Column(
        children: [
          SizedBox(height: 10),
          Text.rich(
            TextSpan(
              text: isEmailSent
                  ? S.of(context).WeHaveSentVerificationEmailTo
                  : S.of(context).YourEmailIsNotVerifiedYet,
              style: _contentStyle,
              children: isEmailSent
                  ? [
                      TextSpan(
                        text: widget.email,
                        style: _emailStyle,
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
        if (!isEmailSent)
          CupertinoDialogAction(
            onPressed: () => _sendEmail(widget.email),
            child: Text(
              S.of(context).SendEmail,
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
          ),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            isEmailSent ? S.of(context).OK : S.of(context).Cancel,
            style: isEmailSent
                ? TextStyle(color: CupertinoColors.activeBlue)
                : TextStyle(color: CupertinoColors.systemRed),
          ),
        ),
      ],
    );
  }
}
