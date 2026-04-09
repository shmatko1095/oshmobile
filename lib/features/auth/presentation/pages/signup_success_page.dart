import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_page_scaffold.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/generated/l10n.dart';

class SignUpSuccessPage extends StatelessWidget {
  static MaterialPageRoute<void> route() => MaterialPageRoute<void>(
        settings: const RouteSettings(name: OshAnalyticsScreens.signUpSuccess),
        builder: (context) => const SignUpSuccessPage(),
      );

  const SignUpSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      title: S.of(context).RegistrationSuccessful,
      subtitle: S.of(context).RegistrationSuccessfulContent,
      preTitle: Icon(
        CupertinoIcons.mail,
        color: AppPalette.accentPrimary,
        size: 76,
      ),
      body: const SizedBox.shrink(),
      footer: CustomElevatedButton(
        buttonText: S.of(context).GoToLogin,
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    );
  }
}
