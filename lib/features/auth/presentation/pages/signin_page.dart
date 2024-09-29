import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
          if (state is AuthFailure) {
            showSnackBar(context, state.message);
          } else if (state is AuthSuccess) {
            Navigator.pushAndRemoveUntil(
              context,
              BlogPage.route(),
              (route) => false,
            );
          }
        }, builder: (context, state) {
          if (state is AuthLoading) {
            return const Loader();
          } else {
            return Column(
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
                  controller: emailController,
                ),
                const SizedBox(height: 15),
                AuthField(
                  hintText: "Password",
                  controller: passwordController,
                  isObscureText: true,
                ),
                const SizedBox(height: 20),
                AuthGradientButton(
                  buttonText: "Sign In",
                  onPressed: () => context.read<AuthBloc>().add(
                        AuthSignIn(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        ),
                      ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.push(context, SignUpPage.route()),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: Theme.of(context).textTheme.titleMedium,
                      children: [
                        TextSpan(
                          text: "Sign Up",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppPalette.gradient2,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }
}
