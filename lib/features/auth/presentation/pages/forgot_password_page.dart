import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_field.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/generated/l10n.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String email;

  static route(String email) => CupertinoPageRoute(
      builder: (context) => ForgotPasswordPage(email: email));

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
      Navigator.pushAndRemoveUntil(
        context,
        SignInPage.route(),
        (route) => false,
      );
    } else if (state is AuthFailed) {
      SnackBarUtils.showFail(
        context: context,
        content: state.message ?? S.of(context).UnknownError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) => _onAuthStateChanged(context, state),
          builder: (context, state) {
            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      S.of(context).ForgotPassword,
                      style: TextStyles.titleStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      S.of(context).ForgotPasswordContent,
                      style: TextStyles.contentStyle,
                    ),
                    const SizedBox(height: 30),
                    AuthField(
                      labelText: S.of(context).Email,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 50),
                    (state is AuthLoading)
                        ? const CupertinoActivityIndicator()
                        : CustomElevatedButton(
                            buttonText: S.of(context).ResetPassword,
                            onPressed: () => _resetPassword(),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
        // ),
      ),
    );
  }
}
