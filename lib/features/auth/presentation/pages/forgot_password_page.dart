import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_field.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';

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

  static const TextStyle _contentStyle = TextStyle(
    fontSize: 16,
    color: CupertinoColors.systemGrey,
  );

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
    if (state is AuthFailed) {
      showSnackBar(
          context: context,
          content: state.message ?? "Unknown error",
          color: AppPalette.errorSnackBarColor);
    } else if (state is AuthSuccess) {
      showSnackBar(
          context: context,
          content: state.message,
          color: AppPalette.successSnackBarColor);
      Navigator.pushAndRemoveUntil(
        context,
        SignInPage.route(),
        (route) => false,
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
                    const Text(
                      "Forgot Password?",
                      style: TextStyles.titleStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Enter your email address, and we’ll send you a link to reset your password. It’s quick and secure.",
                      style: _contentStyle,
                    ),
                    const SizedBox(height: 30),
                    AuthField(
                      labelText: "Email",
                      controller: _emailController,
                    ),
                    const SizedBox(height: 50),
                    (state is AuthLoading)
                        ? const CupertinoActivityIndicator()
                        : CustomElevatedButton(
                            buttonText: "Reset password",
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
