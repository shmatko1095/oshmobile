import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/core/utils/form_validators.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/core/utils/ui_utils.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:oshmobile/features/auth/presentation/pages/signup_page.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_field.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';

part 'verify_email_alert.dart';

class SignInPage extends StatefulWidget {
  static route() =>
      CupertinoPageRoute(builder: (context) => const SignInPage());

  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (_formKey.currentState!.validate() &&
        email.isNotEmpty &&
        password.isNotEmpty) {
      context.read<AuthBloc>().add(
            AuthSignIn(
              email: email,
              password: password,
            ),
          );
    }
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthFailedEmailNotVerified) {
      _showVerifyDialog(context, _emailController.text.trim());
    } else if (state is AuthFailedInvalidUserCredentials) {
      showSnackBar(
          context: context,
          content: "Invalid user credentials",
          color: AppPalette.errorSnackBarColor);
    } else if (state is AuthFailed) {
      showSnackBar(
          context: context,
          content: state.message ?? "Unknown error",
          color: AppPalette.errorSnackBarColor);
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
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const Text(
                              "Sign In",
                              style: TextStyles.titleStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 60),
                            AuthField(
                              labelText: "Email",
                              controller: _emailController,
                              validator: (value) => FormValidator.email(
                                value: value,
                                errorMessage: "Error Email",
                              ),
                            ),
                            const SizedBox(height: 30),
                            AuthField(
                              labelText: "Password",
                              controller: _passwordController,
                              isObscureText: true,
                              validator: (value) => FormValidator.length(
                                value: value,
                                length: 8,
                                errorMessage: "Error Password",
                              ),
                            ),
                            const SizedBox(height: 50),
                            (state is AuthLoading)
                                ? CupertinoActivityIndicator()
                                : CustomElevatedButton(
                                    buttonText: "Sign In",
                                    onPressed: () => _signIn(),
                                  ),
                            const SizedBox(height: 30),
                            CustomElevatedButton(
                              icon: Image.asset("assets/images/google-icon.png",
                                  height: 25),
                              buttonText: "Continue with Google",
                              backgroundColor: isDarkUi(context)
                                  ? AppPalette.activeTextFieldColorDark
                                  : AppPalette.activeTextFieldColorLight,
                              onPressed: () => {},
                            ),
                            const SizedBox(height: 30),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  ForgotPasswordPage.route(
                                      _emailController.text.trim())),
                              child: Text(
                                "Forgot your password",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24, thickness: 1),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(context, SignUpPage.route()),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account?",
                        style: Theme.of(context).textTheme.titleSmall,
                        children: [
                          TextSpan(text: "  "),
                          TextSpan(
                            text: "Sign Up",
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: AppPalette.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      "Try Demo",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              );
              // }
            },
          )),
    );
  }
}
