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
    assert(
        _current != null, 'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false) ? locale.languageCode : locale.toString();
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

  /// `Sign Out`
  String get SignOut {
    return Intl.message(
      'Sign Out',
      name: 'SignOut',
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

  /// `Successful`
  String get Successful {
    return Intl.message(
      'Successful',
      name: 'Successful',
      desc: '',
      args: [],
    );
  }

  /// `Almost There!`
  String get RegistrationSuccessful {
    return Intl.message(
      'Almost There!',
      name: 'RegistrationSuccessful',
      desc: '',
      args: [],
    );
  }

  /// `The last step is to verify your email address. Please check your inbox and follow the instructions to complete your registration.`
  String get RegistrationSuccessfulContent {
    return Intl.message(
      'The last step is to verify your email address. Please check your inbox and follow the instructions to complete your registration.',
      name: 'RegistrationSuccessfulContent',
      desc: '',
      args: [],
    );
  }

  /// `Go to Login`
  String get GoToLogin {
    return Intl.message(
      'Go to Login',
      name: 'GoToLogin',
      desc: '',
      args: [],
    );
  }

  /// `Add device`
  String get AddDevice {
    return Intl.message(
      'Add device',
      name: 'AddDevice',
      desc: '',
      args: [],
    );
  }

  /// `No devices yet`
  String get NoDevicesYet {
    return Intl.message(
      'No devices yet',
      name: 'NoDevicesYet',
      desc: '',
      args: [],
    );
  }

  /// `Unlink Device`
  String get UnlinkDevice {
    return Intl.message(
      'Unlink Device',
      name: 'UnlinkDevice',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get Yes {
    return Intl.message(
      'Yes',
      name: 'Yes',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get No {
    return Intl.message(
      'No',
      name: 'No',
      desc: '',
      args: [],
    );
  }

  /// `The device `
  String get DeviceUnlinkAlertContent1 {
    return Intl.message(
      'The device ',
      name: 'DeviceUnlinkAlertContent1',
      desc: '',
      args: [],
    );
  }

  /// ` will be removed from your list. You can re-add it anytime by scanning the QR code again.`
  String get DeviceUnlinkAlertContent2 {
    return Intl.message(
      ' will be removed from your list. You can re-add it anytime by scanning the QR code again.',
      name: 'DeviceUnlinkAlertContent2',
      desc: '',
      args: [],
    );
  }

  /// `Unknown device type`
  String get UnknownDeviceType {
    return Intl.message(
      'Unknown device type',
      name: 'UnknownDeviceType',
      desc: '',
      args: [],
    );
  }

  /// `No device selected`
  String get NoDeviceSelected {
    return Intl.message(
      'No device selected',
      name: 'NoDeviceSelected',
      desc: '',
      args: [],
    );
  }

  /// `Serial number`
  String get SerialNumber {
    return Intl.message(
      'Serial number',
      name: 'SerialNumber',
      desc: '',
      args: [],
    );
  }

  /// `Secure code`
  String get SecureCode {
    return Intl.message(
      'Secure code',
      name: 'SecureCode',
      desc: '',
      args: [],
    );
  }

  /// `Invalid value`
  String get InvalidValue {
    return Intl.message(
      'Invalid value',
      name: 'InvalidValue',
      desc: '',
      args: [],
    );
  }

  /// `Point the camera at the QR code`
  String get PointCameraToQR {
    return Intl.message(
      'Point the camera at the QR code',
      name: 'PointCameraToQR',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get Done {
    return Intl.message(
      'Done',
      name: 'Done',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get Failed {
    return Intl.message(
      'Failed',
      name: 'Failed',
      desc: '',
      args: [],
    );
  }

  /// `Device information`
  String get DeviceEditTitle {
    return Intl.message(
      'Device information',
      name: 'DeviceEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get Name {
    return Intl.message(
      'Name',
      name: 'Name',
      desc: '',
      args: [],
    );
  }

  /// `Room`
  String get Room {
    return Intl.message(
      'Room',
      name: 'Room',
      desc: '',
      args: [],
    );
  }

  /// `Online`
  String get Online {
    return Intl.message(
      'Online',
      name: 'Online',
      desc: '',
      args: [],
    );
  }

  /// `Offline`
  String get Offline {
    return Intl.message(
      'Offline',
      name: 'Offline',
      desc: '',
      args: [],
    );
  }

  /// `Tips`
  String get Tips {
    return Intl.message(
      'Tips',
      name: 'Tips',
      desc: '',
      args: [],
    );
  }

  /// `Make sure the app is updated to the latest version.`
  String get TipEnsureAppUpdated {
    return Intl.message(
      'Make sure the app is updated to the latest version.',
      name: 'TipEnsureAppUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Check the device's network connection.`
  String get TipCheckNetwork {
    return Intl.message(
      'Check the device\'s network connection.',
      name: 'TipCheckNetwork',
      desc: '',
      args: [],
    );
  }

  /// `Contact support and provide the Model ID and Device ID.`
  String get TipContactSupport {
    return Intl.message(
      'Contact support and provide the Model ID and Device ID.',
      name: 'TipContactSupport',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get Settings {
    return Intl.message(
      'Settings',
      name: 'Settings',
      desc: '',
      args: [],
    );
  }

  /// `Update`
  String get Update {
    return Intl.message(
      'Update',
      name: 'Update',
      desc: '',
      args: [],
    );
  }

  /// `Device details`
  String get DeviceDetails {
    return Intl.message(
      'Device details',
      name: 'DeviceDetails',
      desc: '',
      args: [],
    );
  }

  /// `This device model is not yet supported by the current version of the app. You can try refreshing the data, opening the device settings, or sending a report.`
  String get UnsupportedDeviceMessage {
    return Intl.message(
      'This device model is not yet supported by the current version of the app. You can try refreshing the data, opening the device settings, or sending a report.',
      name: 'UnsupportedDeviceMessage',
      desc: '',
      args: [],
    );
  }

  /// `Target {temp}`
  String Target(Object temp) {
    return Intl.message(
      'Target $temp',
      name: 'Target',
      desc: '',
      args: [temp],
    );
  }

  /// `Next {temp} at {time}`
  String NextAt(Object temp, Object time) {
    return Intl.message(
      'Next $temp at $time',
      name: 'NextAt',
      desc: '',
      args: [temp, time],
    );
  }

  /// `Heating`
  String get Heating {
    return Intl.message(
      'Heating',
      name: 'Heating',
      desc: '',
      args: [],
    );
  }

  /// `Off`
  String get ModeOff {
    return Intl.message(
      'Off',
      name: 'ModeOff',
      desc: '',
      args: [],
    );
  }

  /// `Antifreeze`
  String get ModeAntifreeze {
    return Intl.message(
      'Antifreeze',
      name: 'ModeAntifreeze',
      desc: '',
      args: [],
    );
  }

  /// `On`
  String get ModeOn {
    return Intl.message(
      'On',
      name: 'ModeOn',
      desc: '',
      args: [],
    );
  }

  /// `Daily`
  String get ModeDaily {
    return Intl.message(
      'Daily',
      name: 'ModeDaily',
      desc: '',
      args: [],
    );
  }

  /// `Weekly`
  String get ModeWeekly {
    return Intl.message(
      'Weekly',
      name: 'ModeWeekly',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get Save {
    return Intl.message(
      'Save',
      name: 'Save',
      desc: '',
      args: [],
    );
  }

  /// `Manual temperature`
  String get ManualTemperature {
    return Intl.message(
      'Manual temperature',
      name: 'ManualTemperature',
      desc: '',
      args: [],
    );
  }

  /// `Deleted`
  String get Deleted {
    return Intl.message(
      'Deleted',
      name: 'Deleted',
      desc: '',
      args: [],
    );
  }

  /// `Undo`
  String get Undo {
    return Intl.message(
      'Undo',
      name: 'Undo',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get Retry {
    return Intl.message(
      'Retry',
      name: 'Retry',
      desc: '',
      args: [],
    );
  }

  /// `Mon`
  String get MonShort {
    return Intl.message(
      'Mon',
      name: 'MonShort',
      desc: '',
      args: [],
    );
  }

  /// `Tue`
  String get TueShort {
    return Intl.message(
      'Tue',
      name: 'TueShort',
      desc: '',
      args: [],
    );
  }

  /// `Wed`
  String get WedShort {
    return Intl.message(
      'Wed',
      name: 'WedShort',
      desc: '',
      args: [],
    );
  }

  /// `Thu`
  String get ThuShort {
    return Intl.message(
      'Thu',
      name: 'ThuShort',
      desc: '',
      args: [],
    );
  }

  /// `Fri`
  String get FriShort {
    return Intl.message(
      'Fri',
      name: 'FriShort',
      desc: '',
      args: [],
    );
  }

  /// `Sat`
  String get SatShort {
    return Intl.message(
      'Sat',
      name: 'SatShort',
      desc: '',
      args: [],
    );
  }

  /// `Sun`
  String get SunShort {
    return Intl.message(
      'Sun',
      name: 'SunShort',
      desc: '',
      args: [],
    );
  }

  /// `Set temperature`
  String get SetTemperature {
    return Intl.message(
      'Set temperature',
      name: 'SetTemperature',
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
