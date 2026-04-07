import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/form_validators.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:oshmobile/features/auth/presentation/pages/signup_page.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_field.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_page_scaffold.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/generated/l10n.dart';

part 'verify_email_alert.dart';

class SignInPage extends StatefulWidget {
  static CupertinoPageRoute route() =>
      CupertinoPageRoute(builder: (context) => const SignInPage());

  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _minPasswordLen = 8;

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
      context
          .read<AuthBloc>()
          .add(AuthSignIn(email: email, password: password));
    }
  }

  void _signInWithGoogle() {
    context.read<AuthBloc>().add(AuthSignInWithGoogle());
  }

  void _signInDemo() {
    context.read<AuthBloc>().add(AuthSignInDemo());
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthFailedEmailNotVerified) {
      _showVerifyDialog(context, _emailController.text.trim());
    } else if (state is AuthFailedInvalidUserCredentials) {
      SnackBarUtils.showFail(
        context: context,
        content: S.of(context).InvalidUserCredentials,
      );
    } else if (state is AuthFailed) {
      SnackBarUtils.showFail(
        context: context,
        content: state.message ?? S.of(context).UnknownError,
      );
    }
  }

  Color _secondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppPalette.textSecondary
        : AppPalette.lightTextSecondary;
  }

  Color _secondaryButtonBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppPalette.surfaceRaised
        : AppPalette.white;
  }

  Color _secondaryButtonForeground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppPalette.textPrimary
        : AppPalette.lightTextPrimary;
  }

  Widget _buildFooter(BuildContext context, AuthState state) {
    final isLoading = state is AuthLoading;
    final theme = Theme.of(context);
    final secondaryTextColor = _secondaryTextColor(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              S.of(context).DontHaveAnAccount,
              style: theme.textTheme.titleSmall?.copyWith(
                color: secondaryTextColor,
              ),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.push(context, SignUpPage.route()),
              child: Text(
                S.of(context).SignUp,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : _signInDemo,
            child: Text(
              S.of(context).TryDemo,
              style: theme.textTheme.titleSmall?.copyWith(
                color: secondaryTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          ModalRoute.of(context)?.isCurrent ?? true,
      listener: (context, state) => _onAuthStateChanged(context, state),
      builder: (context, state) {
        return AuthPageScaffold(
          title: S.of(context).SignIn,
          pinFooterToBottom: true,
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
                const SizedBox(height: 24),
                AuthField(
                  labelText: S.of(context).Password,
                  controller: _passwordController,
                  isObscureText: true,
                  validator: (value) => FormValidator.length(
                    value: value,
                    length: _minPasswordLen,
                    errorMessage:
                        S.of(context).InvalidPassword(_minPasswordLen),
                  ),
                ),
                const SizedBox(height: 28),
                (state is AuthLoading)
                    ? const Center(child: CupertinoActivityIndicator())
                    : CustomElevatedButton(
                        buttonText: S.of(context).SignIn,
                        onPressed: _signIn,
                      ),
                const SizedBox(height: 14),
                CustomElevatedButton(
                  icon: Image.asset(
                    "assets/images/google-icon.png",
                    height: 25,
                  ),
                  buttonText: S.of(context).ContinueWithGoogle,
                  backgroundColor: _secondaryButtonBackground(context),
                  foregroundColor: _secondaryButtonForeground(context),
                  onPressed: _signInWithGoogle,
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    ForgotPasswordPage.route(_emailController.text.trim()),
                  ),
                  child: Text(
                    S.of(context).ForgotYourPassword,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _secondaryTextColor(context),
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
              ],
            ),
          ),
          footer: _buildFooter(context, state),
        );
      },
    );
  }
}
