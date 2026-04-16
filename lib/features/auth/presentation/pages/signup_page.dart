import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/form_validators.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/signup_success_page.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_field.dart';
import 'package:oshmobile/features/auth/presentation/widgets/auth_page_scaffold.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/generated/l10n.dart';

class SignUpPage extends StatefulWidget {
  static MaterialPageRoute<void> route() => MaterialPageRoute<void>(
        settings: const RouteSettings(name: OshAnalyticsScreens.signUp),
        builder: (context) => const SignUpPage(),
      );

  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _credentialsFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();

  static const _minNameLen = 3;
  static const _maxNameLen = 60;
  static const _minPasswordLen = 8;
  static const _totalSteps = 2;

  int _currentStep = 0;

  bool get _isCredentialsStep => _currentStep == 0;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    final isValid = _credentialsFormKey.currentState?.validate() ?? false;
    if (isValid) {
      setState(() {
        _currentStep = 1;
      });
    }
  }

  void _goToPreviousStep() {
    if (_isCredentialsStep) return;
    setState(() {
      _currentStep = 0;
    });
  }

  void _signUp() {
    // Step 1 form is not mounted on step 2 (AnimatedSwitcher), so null state
    // here should be treated as already validated by the "Next" action.
    final isCredentialsValid =
        _credentialsFormKey.currentState?.validate() ?? true;
    final isProfileValid = _profileFormKey.currentState?.validate() ?? false;
    if (!isCredentialsValid) {
      setState(() {
        _currentStep = 0;
      });
      return;
    }
    if (!isProfileValid) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty) {
      context.read<AuthBloc>().add(AuthSignUp(
            lastName: lastName,
            firstName: firstName,
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

  Widget _buildCredentialsStep(BuildContext context) {
    return Form(
      key: _credentialsFormKey,
      child: Column(
        key: const ValueKey('credentials_step'),
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
        ],
      ),
    );
  }

  Widget _buildProfileStep(BuildContext context) {
    return Form(
      key: _profileFormKey,
      child: Column(
        key: const ValueKey('profile_step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthField(
            labelText: S.of(context).FirstName,
            controller: _firstNameController,
            validator: (value) => FormValidator.lengthRange(
              value: value,
              min: _minNameLen,
              max: _maxNameLen,
              errorMessage:
                  S.of(context).InvalidFirstName(_minNameLen, _maxNameLen),
            ),
          ),
          const SizedBox(height: 30),
          AuthField(
            labelText: S.of(context).LastName,
            controller: _lastNameController,
            validator: (value) => FormValidator.lengthRange(
              value: value,
              min: _minNameLen,
              max: _maxNameLen,
              errorMessage:
                  S.of(context).InvalidLastName(_minNameLen, _maxNameLen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AuthState state) {
    if (state is AuthLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isCredentialsStep) {
      return CustomElevatedButton(
        buttonText: S.of(context).Next,
        onPressed: _goToNextStep,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _goToPreviousStep,
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(S.of(context).Back),
          ),
        ),
        const SizedBox(height: 10),
        CustomElevatedButton(
          buttonText: S.of(context).SignUp,
          onPressed: _signUp,
        ),
      ],
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final trackColor = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.separator
        : AppPalette.lightBorderSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          S.of(context).StepOf(_currentStep + 1, _totalSteps),
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: (_currentStep + 1) / _totalSteps,
            color: AppPalette.accentPrimary,
            backgroundColor: trackColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(context),
        const SizedBox(height: 16),
        _buildActionButtons(context, state),
        const SizedBox(height: 8),
        if (!_isCredentialsStep)
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).GoToLogin),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isCredentialsStep,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _isCredentialsStep) return;
        _goToPreviousStep();
      },
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) => _onAuthStateChanged(context, state),
        builder: (context, state) {
          return AuthPageScaffold(
            appBar: AppBar(
              automaticallyImplyLeading: _isCredentialsStep,
              leading: _isCredentialsStep
                  ? null
                  : BackButton(
                      onPressed: _goToPreviousStep,
                    ),
            ),
            title: S.of(context).SignUp,
            body: AnimatedSwitcher(
              duration: AppPalette.motionBase,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _isCredentialsStep
                  ? _buildCredentialsStep(context)
                  : _buildProfileStep(context),
            ),
            footer: _buildFooter(context, state),
          );
        },
      ),
    );
  }
}
