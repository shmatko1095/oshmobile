import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/utils/form_validators.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_field.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_page_scaffold.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/generated/l10n.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String email;

  static MaterialPageRoute<void> route(String email) =>
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: OshAnalyticsScreens.forgotPassword,
        ),
        builder: (context) => ForgotPasswordPage(email: email),
      );

  const ForgotPasswordPage({required this.email, super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _emailController.text = widget.email;
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    final email = _emailController.text.trim();
    if (_formKey.currentState!.validate() && email.isNotEmpty) {
      context.read<AuthBloc>().add(AuthSendResetPasswordEmail(email: email));
    }
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      SnackBarUtils.showSuccess(
        context: context,
        content: state.message,
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (state is AuthFailed) {
      SnackBarUtils.showFail(
        context: context,
        content: state.message ?? S.of(context).UnknownError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) => _onAuthStateChanged(context, state),
      builder: (context, state) {
        return AuthPageScaffold(
          title: S.of(context).ForgotPassword,
          subtitle: S.of(context).ForgotPasswordContent,
          subtitleAlign: TextAlign.left,
          body: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthField(
                  labelText: S.of(context).Email,
                  controller: _emailController,
                  validator: (value) => FormValidator.email(
                    value: value,
                    errorMessage: S.of(context).InvalidEmailAddress,
                  ),
                ),
                const SizedBox(height: 28),
                (state is AuthLoading)
                    ? const Center(child: CupertinoActivityIndicator())
                    : CustomElevatedButton(
                        buttonText: S.of(context).ResetPassword,
                        onPressed: _resetPassword,
                      ),
              ],
            ),
          ),
          footer: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).GoToLogin),
            ),
          ),
        );
      },
    );
  }
}
