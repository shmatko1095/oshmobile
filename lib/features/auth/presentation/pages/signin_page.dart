import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/form_validators.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/signup_page.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_field.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_gradient_button.dart';
import 'package:oshmobile/features/blog/presentation/pages/blog_page.dart';

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
    if (state is AuthFailure) {
      showSnackBar(context, state.message);
    } else if (state is AuthSuccess) {
      Navigator.pushAndRemoveUntil(
        context,
        BlogPage.route(),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) => _onAuthStateChanged(context, state),
              builder: (context, state) {
                if (state is AuthLoading) {
                  return const Loader();
                } else {
                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        AuthField(
                          hintText: "Email",
                          labelText: "Email",
                          controller: _emailController,
                          validator: (value) => FormValidator.email(
                            value: value,
                            errorMessage: "Error Email",
                          ),
                        ),
                        const SizedBox(height: 15),
                        AuthField(
                          hintText: "Password",
                          labelText: "Password",
                          controller: _passwordController,
                          isObscureText: true,
                          validator: (value) => FormValidator.length(
                            value: value,
                            length: 8,
                            errorMessage: "Error Password",
                          ),
                        ),
                        const SizedBox(height: 20),
                        AuthGradientButton(
                          buttonText: "Sign In",
                          onPressed: () => _signIn(),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () =>
                              Navigator.push(context, SignUpPage.route()),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: Theme.of(context).textTheme.titleMedium,
                              children: [
                                TextSpan(
                                  text: "Sign Up",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppPalette.gradient2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            "Try Demo",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }),
        ),
      ),

    );
  }
}
