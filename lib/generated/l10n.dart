// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Sign In`
  String get SignIn {
    return Intl.message(
      'Sign In',
      name: 'SignIn',
      desc: '',
      args: [],
    );
  }

  /// `Sign Up`
  String get SignUp {
    return Intl.message(
      'Sign Up',
      name: 'SignUp',
      desc: '',
      args: [],
    );
  }

  /// `Invalid user credentials`
  String get InvalidUserCredentials {
    return Intl.message(
      'Invalid user credentials',
      name: 'InvalidUserCredentials',
      desc: '',
      args: [],
    );
  }

  /// `Unknown error`
  String get UnknownError {
    return Intl.message(
      'Unknown error',
      name: 'UnknownError',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get Email {
    return Intl.message(
      'Email',
      name: 'Email',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get Password {
    return Intl.message(
      'Password',
      name: 'Password',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email address`
  String get InvalidEmailAddress {
    return Intl.message(
      'Invalid email address',
      name: 'InvalidEmailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Password must be at least {length} characters long`
  String InvalidPassword(Object length) {
    return Intl.message(
      'Password must be at least $length characters long',
      name: 'InvalidPassword',
      desc: '',
      args: [length],
    );
  }

  /// `Continue with Google`
  String get ContinueWithGoogle {
    return Intl.message(
      'Continue with Google',
      name: 'ContinueWithGoogle',
      desc: '',
      args: [],
    );
  }

  /// `Forgot your password`
  String get ForgotYourPassword {
    return Intl.message(
      'Forgot your password',
      name: 'ForgotYourPassword',
      desc: '',
      args: [],
    );
  }

  /// `Try Demo`
  String get TryDemo {
    return Intl.message(
      'Try Demo',
      name: 'TryDemo',
      desc: '',
      args: [],
    );
  }

  /// `Don't have an account?`
  String get DontHaveAnAccount {
    return Intl.message(
      'Don\'t have an account?',
      name: 'DontHaveAnAccount',
      desc: '',
      args: [],
    );
  }

  /// `User already exist`
  String get UserAlreadyExist {
    return Intl.message(
      'User already exist',
      name: 'UserAlreadyExist',
      desc: '',
      args: [],
    );
  }

  /// `Password confirmation`
  String get PasswordConfirmation {
    return Intl.message(
      'Password confirmation',
      name: 'PasswordConfirmation',
      desc: '',
      args: [],
    );
  }

  /// `Passwords do not match`
  String get PasswordsDoNotMatch {
    return Intl.message(
      'Passwords do not match',
      name: 'PasswordsDoNotMatch',
      desc: '',
      args: [],
    );
  }

  /// `Forgot password?`
  String get ForgotPassword {
    return Intl.message(
      'Forgot password?',
      name: 'ForgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email address, and we’ll send you a link to reset your password. It’s quick and secure.`
  String get ForgotPasswordContent {
    return Intl.message(
      'Enter your email address, and we’ll send you a link to reset your password. It’s quick and secure.',
      name: 'ForgotPasswordContent',
      desc: '',
      args: [],
    );
  }

  /// `Reset password`
  String get ResetPassword {
    return Intl.message(
      'Reset password',
      name: 'ResetPassword',
      desc: '',
      args: [],
    );
  }

  /// `Check your email`
  String get CheckYourEmail {
    return Intl.message(
      'Check your email',
      name: 'CheckYourEmail',
      desc: '',
      args: [],
    );
  }

  /// `Verify your email`
  String get VerifyYourEmail {
    return Intl.message(
      'Verify your email',
      name: 'VerifyYourEmail',
      desc: '',
      args: [],
    );
  }

  /// `We have sent a verification email to `
  String get WeHaveSentVerificationEmailTo {
    return Intl.message(
      'We have sent a verification email to ',
      name: 'WeHaveSentVerificationEmailTo',
      desc: '',
      args: [],
    );
  }

  /// `Your email is not verified yet. Click the button below to resend the verification email.`
  String get YourEmailIsNotVerifiedYet {
    return Intl.message(
      'Your email is not verified yet. Click the button below to resend the verification email.',
      name: 'YourEmailIsNotVerifiedYet',
      desc: '',
      args: [],
    );
  }

  /// `. Please check your inbox and follow the instructions to complete your registration.`
  String get PleaseCheckYourInbox {
    return Intl.message(
      '. Please check your inbox and follow the instructions to complete your registration.',
      name: 'PleaseCheckYourInbox',
      desc: '',
      args: [],
    );
  }

  /// `Send email`
  String get SendEmail {
    return Intl.message(
      'Send email',
      name: 'SendEmail',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get OK {
    return Intl.message(
      'OK',
      name: 'OK',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get Cancel {
    return Intl.message(
      'Cancel',
      name: 'Cancel',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'uk'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
