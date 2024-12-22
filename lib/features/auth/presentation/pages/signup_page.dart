import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/form_validators.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_field.dart';
import 'package:oshmobile/features/auth/presentation/widgets/gradient_elevated_button.dart';
import 'package:oshmobile/features/blog/presentation/pages/blog_page.dart';

class SignUpPage extends StatefulWidget {
  static route() =>
      CupertinoPageRoute(builder: (context) => const SignUpPage());

  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  void _signUp() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (_formKey.currentState!.validate() &&
        email.isNotEmpty &&
        password.isNotEmpty) {
      context.read<AuthBloc>().add(AuthSignUp(
            lastName: "",
            firstName: "",
            email: email,
            password: password,
          ));
    }
  }

  //CALENDAR VIEW
  //FL CHART
  // awesome snackbars
  // chashed network images
  // animations

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthFailed) {
      showSnackBar(context: context, content: state.error, color: AppPalette.errorSnackBarColor);
    } else if (state is AuthSuccess) {
      showSnackBar(context: context, content: state.message, color: AppPalette.successSnackBarColor);
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
            if (state is AuthLoading) {
              return const Loader();
            } else {
              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),
                      AuthField(
                        hintText: "Email",
                        labelText: "Email",
                        controller: _emailController,
                        validator: (value) => FormValidator.email(
                          value: value,
                          errorMessage: "Error Email",
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 15),
                      AuthField(
                        hintText: "Password confirmation",
                        labelText: "Password confirmation",
                        controller: _passwordConfirmationController,
                        isObscureText: true,
                        validator: (value) => FormValidator.same(
                          value: value,
                          same: _passwordController.text.trim(),
                          errorMessage: "Error Name",
                        ),
                      ),
                      const SizedBox(height: 20),
                      GradientElevatedButton(
                        buttonText: "Sign Up",
                        onPressed: () => _signUp(),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
        // ),
      ),
    );
  }
}
