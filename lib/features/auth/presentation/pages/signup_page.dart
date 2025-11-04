import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/core/utils/form_validators.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/signup_success_page.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_field.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/generated/l10n.dart';

class SignUpPage extends StatefulWidget {
  static CupertinoPageRoute route() => CupertinoPageRoute(builder: (context) => const SignUpPage());

  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _minPasswordLen = 8;

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
    if (_formKey.currentState!.validate() && email.isNotEmpty && password.isNotEmpty) {
      context.read<AuthBloc>().add(AuthSignUp(
            lastName: "",
            firstName: "",
            email: email,
            password: password,
          ));
    }
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthConflict) {
      SnackBarUtils.showFail(
        context: context,
        content: S.of(context).UserAlreadyExist,
      );
    } else if (state is AuthSuccess) {
      Navigator.pushReplacement(
        context,
        SignUpSuccessPage.route(),
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
                      S.of(context).SignUp,
                      style: TextStyles.titleStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),
                    AuthField(
                      labelText: S.of(context).Email,
                      controller: _emailController,
                      validator: (value) => FormValidator.email(
                        value: value,
                        errorMessage: S.of(context).InvalidEmailAddress,
                      ),
                    ),
                    const SizedBox(height: 30),
                    AuthField(
                      labelText: S.of(context).Password,
                      controller: _passwordController,
                      isObscureText: true,
                      validator: (value) => FormValidator.length(
                        value: value,
                        length: _minPasswordLen,
                        errorMessage: S.of(context).InvalidPassword(_minPasswordLen),
                      ),
                    ),
                    const SizedBox(height: 30),
                    AuthField(
                      labelText: S.of(context).PasswordConfirmation,
                      controller: _passwordConfirmationController,
                      isObscureText: true,
                      validator: (value) => FormValidator.same(
                        value: value,
                        same: _passwordController.text.trim(),
                        errorMessage: S.of(context).PasswordsDoNotMatch,
                      ),
                    ),
                    const SizedBox(height: 50),
                    (state is AuthLoading)
                        ? CupertinoActivityIndicator()
                        : CustomElevatedButton(
                            buttonText: S.of(context).SignUp,
                            onPressed: () => _signUp(),
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
