import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/generated/l10n.dart';

class SignUpSuccessPage extends StatelessWidget {
  static CupertinoPageRoute route() => CupertinoPageRoute(builder: (context) => const SignUpSuccessPage());

  const SignUpSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                CupertinoIcons.mail,
                color: CupertinoColors.activeBlue,
                size: 80.0,
              ),
              const SizedBox(height: 50),
              Text(
                S.of(context).RegistrationSuccessful,
                style: TextStyles.titleStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Text(
                S.of(context).RegistrationSuccessfulContent,
                style: TextStyles.contentStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              CustomElevatedButton(
                buttonText: S.of(context).GoToLogin,
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
