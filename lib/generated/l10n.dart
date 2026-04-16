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
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
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
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Sign In`
  String get SignIn {
    return Intl.message('Sign In', name: 'SignIn', desc: '', args: []);
  }

  /// `Sign Up`
  String get SignUp {
    return Intl.message('Sign Up', name: 'SignUp', desc: '', args: []);
  }

  /// `Back`
  String get Back {
    return Intl.message('Back', name: 'Back', desc: '', args: []);
  }

  /// `Next`
  String get Next {
    return Intl.message('Next', name: 'Next', desc: '', args: []);
  }

  /// `Step {current} of {total}`
  String StepOf(Object current, Object total) {
    return Intl.message(
      'Step $current of $total',
      name: 'StepOf',
      desc: '',
      args: [current, total],
    );
  }

  /// `Sign Out`
  String get SignOut {
    return Intl.message('Sign Out', name: 'SignOut', desc: '', args: []);
  }

  /// `Profile & settings`
  String get ProfileAndSettings {
    return Intl.message(
      'Profile & settings',
      name: 'ProfileAndSettings',
      desc: '',
      args: [],
    );
  }

  /// `Application settings`
  String get ApplicationSettings {
    return Intl.message(
      'Application settings',
      name: 'ApplicationSettings',
      desc: '',
      args: [],
    );
  }

  /// `Account settings`
  String get AccountSettings {
    return Intl.message(
      'Account settings',
      name: 'AccountSettings',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get Account {
    return Intl.message('Account', name: 'Account', desc: '', args: []);
  }

  /// `System`
  String get ThemeSystem {
    return Intl.message('System', name: 'ThemeSystem', desc: '', args: []);
  }

  /// `Dark`
  String get ThemeDark {
    return Intl.message('Dark', name: 'ThemeDark', desc: '', args: []);
  }

  /// `Light`
  String get ThemeLight {
    return Intl.message('Light', name: 'ThemeLight', desc: '', args: []);
  }

  /// `Delete`
  String get Delete {
    return Intl.message('Delete', name: 'Delete', desc: '', args: []);
  }

  /// `Delete account`
  String get DeleteAccount {
    return Intl.message(
      'Delete account',
      name: 'DeleteAccount',
      desc: '',
      args: [],
    );
  }

  /// `Permanently remove your account and all associated data.`
  String get DeleteAccountDescription {
    return Intl.message(
      'Permanently remove your account and all associated data.',
      name: 'DeleteAccountDescription',
      desc: '',
      args: [],
    );
  }

  /// `Delete account?`
  String get DeleteAccountConfirmTitle {
    return Intl.message(
      'Delete account?',
      name: 'DeleteAccountConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `This action is permanent and cannot be undone.`
  String get DeleteAccountConfirmMessage {
    return Intl.message(
      'This action is permanent and cannot be undone.',
      name: 'DeleteAccountConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Confirm account deletion`
  String get DeleteAccountEmailFlowTitle {
    return Intl.message(
      'Confirm account deletion',
      name: 'DeleteAccountEmailFlowTitle',
      desc: '',
      args: [],
    );
  }

  /// `For your security, we’ll send a confirmation email. Your account stays active until you confirm deletion in your inbox.`
  String get DeleteAccountEmailFlowDescription {
    return Intl.message(
      'For your security, we’ll send a confirmation email. Your account stays active until you confirm deletion in your inbox.',
      name: 'DeleteAccountEmailFlowDescription',
      desc: '',
      args: [],
    );
  }

  /// `After you confirm from email, your account and related data will be scheduled for deletion.`
  String get DeleteAccountEmailFlowPendingNote {
    return Intl.message(
      'After you confirm from email, your account and related data will be scheduled for deletion.',
      name: 'DeleteAccountEmailFlowPendingNote',
      desc: '',
      args: [],
    );
  }

  /// `Send confirmation email`
  String get DeleteAccountEmailFlowSendButton {
    return Intl.message(
      'Send confirmation email',
      name: 'DeleteAccountEmailFlowSendButton',
      desc: '',
      args: [],
    );
  }

  /// `We sent a confirmation email to {email}. Open it and confirm account deletion.`
  String DeleteAccountEmailFlowSuccessDescription(Object email) {
    return Intl.message(
      'We sent a confirmation email to $email. Open it and confirm account deletion.',
      name: 'DeleteAccountEmailFlowSuccessDescription',
      desc: '',
      args: [email],
    );
  }

  /// `Didn’t request this? You can safely ignore this email.`
  String get DeleteAccountEmailFlowSuccessHint {
    return Intl.message(
      'Didn’t request this? You can safely ignore this email.',
      name: 'DeleteAccountEmailFlowSuccessHint',
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

  /// `First name`
  String get FirstName {
    return Intl.message('First name', name: 'FirstName', desc: '', args: []);
  }

  /// `Last name`
  String get LastName {
    return Intl.message('Last name', name: 'LastName', desc: '', args: []);
  }

  /// `Email`
  String get Email {
    return Intl.message('Email', name: 'Email', desc: '', args: []);
  }

  /// `Password`
  String get Password {
    return Intl.message('Password', name: 'Password', desc: '', args: []);
  }

  /// `First name must be between {min} and {max} characters`
  String InvalidFirstName(Object min, Object max) {
    return Intl.message(
      'First name must be between $min and $max characters',
      name: 'InvalidFirstName',
      desc: '',
      args: [min, max],
    );
  }

  /// `Last name must be between {min} and {max} characters`
  String InvalidLastName(Object min, Object max) {
    return Intl.message(
      'Last name must be between $min and $max characters',
      name: 'InvalidLastName',
      desc: '',
      args: [min, max],
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
    return Intl.message('Try Demo', name: 'TryDemo', desc: '', args: []);
  }

  /// `Demo mode`
  String get DemoMode {
    return Intl.message('Demo mode', name: 'DemoMode', desc: '', args: []);
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
    return Intl.message('Send email', name: 'SendEmail', desc: '', args: []);
  }

  /// `OK`
  String get OK {
    return Intl.message('OK', name: 'OK', desc: '', args: []);
  }

  /// `Cancel`
  String get Cancel {
    return Intl.message('Cancel', name: 'Cancel', desc: '', args: []);
  }

  /// `Successful`
  String get Successful {
    return Intl.message('Successful', name: 'Successful', desc: '', args: []);
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
    return Intl.message('Go to Login', name: 'GoToLogin', desc: '', args: []);
  }

  /// `Add device`
  String get AddDevice {
    return Intl.message('Add device', name: 'AddDevice', desc: '', args: []);
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

  /// `Open devices`
  String get OpenDevices {
    return Intl.message(
      'Open devices',
      name: 'OpenDevices',
      desc: '',
      args: [],
    );
  }

  /// `Remove device?`
  String get RemoveDeviceConfirmTitle {
    return Intl.message(
      'Remove device?',
      name: 'RemoveDeviceConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `The device {deviceName} will be removed from your list. You can re-add it anytime by scanning the QR code again.`
  String RemoveDeviceConfirmMessage(Object deviceName) {
    return Intl.message(
      'The device $deviceName will be removed from your list. You can re-add it anytime by scanning the QR code again.',
      name: 'RemoveDeviceConfirmMessage',
      desc: '',
      args: [deviceName],
    );
  }

  /// `Yes`
  String get Yes {
    return Intl.message('Yes', name: 'Yes', desc: '', args: []);
  }

  /// `No`
  String get No {
    return Intl.message('No', name: 'No', desc: '', args: []);
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

  /// `Choose a device.`
  String get NoDeviceSelectedChooseDeviceSubtitle {
    return Intl.message(
      'Choose a device.',
      name: 'NoDeviceSelectedChooseDeviceSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Add your first device.`
  String get NoDeviceSelectedNoDevicesSubtitle {
    return Intl.message(
      'Add your first device.',
      name: 'NoDeviceSelectedNoDevicesSubtitle',
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
    return Intl.message('Secure code', name: 'SecureCode', desc: '', args: []);
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
    return Intl.message('Done', name: 'Done', desc: '', args: []);
  }

  /// `Failed`
  String get Failed {
    return Intl.message('Failed', name: 'Failed', desc: '', args: []);
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
    return Intl.message('Name', name: 'Name', desc: '', args: []);
  }

  /// `Rename sensor`
  String get SensorRename {
    return Intl.message(
      'Rename sensor',
      name: 'SensorRename',
      desc: '',
      args: [],
    );
  }

  /// `Sensor name`
  String get SensorNameHint {
    return Intl.message(
      'Sensor name',
      name: 'SensorNameHint',
      desc: '',
      args: [],
    );
  }

  /// `Calibration`
  String get SensorCalibration {
    return Intl.message(
      'Calibration',
      name: 'SensorCalibration',
      desc: '',
      args: [],
    );
  }

  /// `Set as reference.`
  String get SensorMakeMain {
    return Intl.message(
      'Set as reference.',
      name: 'SensorMakeMain',
      desc: '',
      args: [],
    );
  }

  /// `Delete sensor`
  String get DeleteSensor {
    return Intl.message(
      'Delete sensor',
      name: 'DeleteSensor',
      desc: '',
      args: [],
    );
  }

  /// `Delete point`
  String get DeletePoint {
    return Intl.message(
      'Delete point',
      name: 'DeletePoint',
      desc: '',
      args: [],
    );
  }

  /// `Device actions`
  String get DeviceActions {
    return Intl.message(
      'Device actions',
      name: 'DeviceActions',
      desc: '',
      args: [],
    );
  }

  /// `Device settings`
  String get DeviceInternalSettings {
    return Intl.message(
      'Device settings',
      name: 'DeviceInternalSettings',
      desc: '',
      args: [],
    );
  }

  /// `Available when the device is online and exposes settings.`
  String get DeviceInternalSettingsUnavailable {
    return Intl.message(
      'Available when the device is online and exposes settings.',
      name: 'DeviceInternalSettingsUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Available when the device is online and the device session is ready.`
  String get DeviceAboutUnavailable {
    return Intl.message(
      'Available when the device is online and the device session is ready.',
      name: 'DeviceAboutUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Rename device`
  String get RenameDeviceAction {
    return Intl.message(
      'Rename device',
      name: 'RenameDeviceAction',
      desc: '',
      args: [],
    );
  }

  /// `Remove device`
  String get RemoveDeviceAction {
    return Intl.message(
      'Remove device',
      name: 'RemoveDeviceAction',
      desc: '',
      args: [],
    );
  }

  /// `Device access`
  String get DeviceAccessTitle {
    return Intl.message(
      'Device access',
      name: 'DeviceAccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `No users with access found.`
  String get DeviceAccessEmpty {
    return Intl.message(
      'No users with access found.',
      name: 'DeviceAccessEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Users are hidden in demo mode.`
  String get DeviceAccessEmptyDemo {
    return Intl.message(
      'Users are hidden in demo mode.',
      name: 'DeviceAccessEmptyDemo',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load device users.`
  String get DeviceAccessLoadFailed {
    return Intl.message(
      'Failed to load device users.',
      name: 'DeviceAccessLoadFailed',
      desc: '',
      args: [],
    );
  }

  /// `Remove my access`
  String get DeviceAccessRemoveMyAccess {
    return Intl.message(
      'Remove my access',
      name: 'DeviceAccessRemoveMyAccess',
      desc: '',
      args: [],
    );
  }

  /// `You`
  String get YouLabel {
    return Intl.message('You', name: 'YouLabel', desc: '', args: []);
  }

  /// `Schedule point actions`
  String get SchedulePointActions {
    return Intl.message(
      'Schedule point actions',
      name: 'SchedulePointActions',
      desc: '',
      args: [],
    );
  }

  /// `Main`
  String get SensorMainLabel {
    return Intl.message('Main', name: 'SensorMainLabel', desc: '', args: []);
  }

  /// `Sensor actions`
  String get SensorMoreActions {
    return Intl.message(
      'Sensor actions',
      name: 'SensorMoreActions',
      desc: '',
      args: [],
    );
  }

  /// `Sensor conditions`
  String get SensorConditions {
    return Intl.message(
      'Sensor conditions',
      name: 'SensorConditions',
      desc: '',
      args: [],
    );
  }

  /// `Room`
  String get Room {
    return Intl.message('Room', name: 'Room', desc: '', args: []);
  }

  /// `Online`
  String get Online {
    return Intl.message('Online', name: 'Online', desc: '', args: []);
  }

  /// `Offline`
  String get Offline {
    return Intl.message('Offline', name: 'Offline', desc: '', args: []);
  }

  /// `Tips`
  String get Tips {
    return Intl.message('Tips', name: 'Tips', desc: '', args: []);
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
    return Intl.message('Settings', name: 'Settings', desc: '', args: []);
  }

  /// `Display`
  String get display {
    return Intl.message('Display', name: 'display', desc: '', args: []);
  }

  /// `Updates`
  String get updates {
    return Intl.message('Updates', name: 'updates', desc: '', args: []);
  }

  /// `Time`
  String get time {
    return Intl.message('Time', name: 'time', desc: '', args: []);
  }

  /// `Heating control`
  String get control {
    return Intl.message('Heating control', name: 'control', desc: '', args: []);
  }

  /// `Active brightness`
  String get displayActiveBrightness {
    return Intl.message(
      'Active brightness',
      name: 'displayActiveBrightness',
      desc: '',
      args: [],
    );
  }

  /// `Idle brightness`
  String get displayIdleBrightness {
    return Intl.message(
      'Idle brightness',
      name: 'displayIdleBrightness',
      desc: '',
      args: [],
    );
  }

  /// `Idle dim timeout`
  String get displayIdleTime {
    return Intl.message(
      'Idle dim timeout',
      name: 'displayIdleTime',
      desc: '',
      args: [],
    );
  }

  /// `Dim on idle`
  String get displayDimOnIdle {
    return Intl.message(
      'Dim on idle',
      name: 'displayDimOnIdle',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get displayLanguage {
    return Intl.message(
      'Language',
      name: 'displayLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Auto update`
  String get updateAutoUpdateEnabled {
    return Intl.message(
      'Auto update',
      name: 'updateAutoUpdateEnabled',
      desc: '',
      args: [],
    );
  }

  /// `Update at midnight`
  String get updateAtMidnight {
    return Intl.message(
      'Update at midnight',
      name: 'updateAtMidnight',
      desc: '',
      args: [],
    );
  }

  /// `Automatic time`
  String get timeAuto {
    return Intl.message('Automatic time', name: 'timeAuto', desc: '', args: []);
  }

  /// `Time zone`
  String get timeZone {
    return Intl.message('Time zone', name: 'timeZone', desc: '', args: []);
  }

  /// `Control model`
  String get controlModel {
    return Intl.message(
      'Control model',
      name: 'controlModel',
      desc: '',
      args: [],
    );
  }

  /// `Max floor temperature`
  String get maxFloorTemperature {
    return Intl.message(
      'Max floor temperature',
      name: 'maxFloorTemperature',
      desc: '',
      args: [],
    );
  }

  /// `Floor temperature limit`
  String get maxFloorTempLimitEnabled {
    return Intl.message(
      'Floor temperature limit',
      name: 'maxFloorTempLimitEnabled',
      desc: '',
      args: [],
    );
  }

  /// `Floor sensor fail-safe`
  String get maxFloorTempFailSafe {
    return Intl.message(
      'Floor sensor fail-safe',
      name: 'maxFloorTempFailSafe',
      desc: '',
      args: [],
    );
  }

  /// `Hysteresis`
  String get hysteresis {
    return Intl.message('Hysteresis', name: 'hysteresis', desc: '', args: []);
  }

  /// `Update`
  String get Update {
    return Intl.message('Update', name: 'Update', desc: '', args: []);
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
    return Intl.message('Target $temp', name: 'Target', desc: '', args: [temp]);
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
    return Intl.message('Heating', name: 'Heating', desc: '', args: []);
  }

  /// `Off`
  String get ModeOff {
    return Intl.message('Off', name: 'ModeOff', desc: '', args: []);
  }

  /// `Range`
  String get ModeRange {
    return Intl.message('Range', name: 'ModeRange', desc: '', args: []);
  }

  /// `On`
  String get ModeOn {
    return Intl.message('On', name: 'ModeOn', desc: '', args: []);
  }

  /// `Daily`
  String get ModeDaily {
    return Intl.message('Daily', name: 'ModeDaily', desc: '', args: []);
  }

  /// `Weekly`
  String get ModeWeekly {
    return Intl.message('Weekly', name: 'ModeWeekly', desc: '', args: []);
  }

  /// `Tap active mode to edit. Hold any mode to configure without switching.`
  String get ThermostatModeBarHint {
    return Intl.message(
      'Tap active mode to edit. Hold any mode to configure without switching.',
      name: 'ThermostatModeBarHint',
      desc: '',
      args: [],
    );
  }

  /// `Tap to edit. Long press to edit without switching.`
  String get ThermostatModeBarSemanticsActiveEditable {
    return Intl.message(
      'Tap to edit. Long press to edit without switching.',
      name: 'ThermostatModeBarSemanticsActiveEditable',
      desc: '',
      args: [],
    );
  }

  /// `Tap to switch. Long press to edit.`
  String get ThermostatModeBarSemanticsInactiveEditable {
    return Intl.message(
      'Tap to switch. Long press to edit.',
      name: 'ThermostatModeBarSemanticsInactiveEditable',
      desc: '',
      args: [],
    );
  }

  /// `Tap to switch off.`
  String get ThermostatModeBarSemanticsOff {
    return Intl.message(
      'Tap to switch off.',
      name: 'ThermostatModeBarSemanticsOff',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get Save {
    return Intl.message('Save', name: 'Save', desc: '', args: []);
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
    return Intl.message('Deleted', name: 'Deleted', desc: '', args: []);
  }

  /// `Undo`
  String get Undo {
    return Intl.message('Undo', name: 'Undo', desc: '', args: []);
  }

  /// `Retry`
  String get Retry {
    return Intl.message('Retry', name: 'Retry', desc: '', args: []);
  }

  /// `Update required`
  String get updateAppRequiredBadge {
    return Intl.message(
      'Update required',
      name: 'updateAppRequiredBadge',
      desc: '',
      args: [],
    );
  }

  /// `Update app to continue`
  String get updateAppRequiredTitle {
    return Intl.message(
      'Update app to continue',
      name: 'updateAppRequiredTitle',
      desc: '',
      args: [],
    );
  }

  /// `This device uses required protocol domains that are newer than the current app build supports.`
  String get updateAppRequiredSubtitle {
    return Intl.message(
      'This device uses required protocol domains that are newer than the current app build supports.',
      name: 'updateAppRequiredSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Update the app to the latest available version on this device.`
  String get updateAppRequiredStepUpdate {
    return Intl.message(
      'Update the app to the latest available version on this device.',
      name: 'updateAppRequiredStepUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Open the device again after the update finishes and the session reconnects.`
  String get updateAppRequiredStepReopen {
    return Intl.message(
      'Open the device again after the update finishes and the session reconnects.',
      name: 'updateAppRequiredStepReopen',
      desc: '',
      args: [],
    );
  }

  /// `If the issue remains after updating, contact support and include the serial number and model ID.`
  String get updateAppRequiredStepContactSupport {
    return Intl.message(
      'If the issue remains after updating, contact support and include the serial number and model ID.',
      name: 'updateAppRequiredStepContactSupport',
      desc: '',
      args: [],
    );
  }

  /// `Compatibility error`
  String get compatibilityErrorBadge {
    return Intl.message(
      'Compatibility error',
      name: 'compatibilityErrorBadge',
      desc: '',
      args: [],
    );
  }

  /// `This device cannot be opened`
  String get compatibilityErrorTitle {
    return Intl.message(
      'This device cannot be opened',
      name: 'compatibilityErrorTitle',
      desc: '',
      args: [],
    );
  }

  /// `The app could not establish a compatible protocol contract for this device right now.`
  String get compatibilityErrorSubtitle {
    return Intl.message(
      'The app could not establish a compatible protocol contract for this device right now.',
      name: 'compatibilityErrorSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Make sure the device is online and the backend bootstrap contract is available.`
  String get compatibilityErrorStepCheckConnection {
    return Intl.message(
      'Make sure the device is online and the backend bootstrap contract is available.',
      name: 'compatibilityErrorStepCheckConnection',
      desc: '',
      args: [],
    );
  }

  /// `Retry after the device reconnects or the backend compatibility issue is resolved.`
  String get compatibilityErrorStepRetry {
    return Intl.message(
      'Retry after the device reconnects or the backend compatibility issue is resolved.',
      name: 'compatibilityErrorStepRetry',
      desc: '',
      args: [],
    );
  }

  /// `If it keeps failing, contact support with the serial number, model ID, and the technical details below.`
  String get compatibilityErrorStepContactSupport {
    return Intl.message(
      'If it keeps failing, contact support with the serial number, model ID, and the technical details below.',
      name: 'compatibilityErrorStepContactSupport',
      desc: '',
      args: [],
    );
  }

  /// `What to do next`
  String get compatibilityNextStepsTitle {
    return Intl.message(
      'What to do next',
      name: 'compatibilityNextStepsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Technical details`
  String get compatibilityTechnicalDetailsTitle {
    return Intl.message(
      'Technical details',
      name: 'compatibilityTechnicalDetailsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Mon`
  String get MonShort {
    return Intl.message('Mon', name: 'MonShort', desc: '', args: []);
  }

  /// `Tue`
  String get TueShort {
    return Intl.message('Tue', name: 'TueShort', desc: '', args: []);
  }

  /// `Wed`
  String get WedShort {
    return Intl.message('Wed', name: 'WedShort', desc: '', args: []);
  }

  /// `Thu`
  String get ThuShort {
    return Intl.message('Thu', name: 'ThuShort', desc: '', args: []);
  }

  /// `Fri`
  String get FriShort {
    return Intl.message('Fri', name: 'FriShort', desc: '', args: []);
  }

  /// `Sat`
  String get SatShort {
    return Intl.message('Sat', name: 'SatShort', desc: '', args: []);
  }

  /// `Sun`
  String get SunShort {
    return Intl.message('Sun', name: 'SunShort', desc: '', args: []);
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

  /// `Choose Wi-Fi`
  String get ChooseWiFi {
    return Intl.message('Choose Wi-Fi', name: 'ChooseWiFi', desc: '', args: []);
  }

  /// `Search`
  String get Search {
    return Intl.message('Search', name: 'Search', desc: '', args: []);
  }

  /// `Choose the wifi network you want to connect your device.`
  String get ChooseWifiToConnect {
    return Intl.message(
      'Choose the wifi network you want to connect your device.',
      name: 'ChooseWifiToConnect',
      desc: '',
      args: [],
    );
  }

  /// `No networks found`
  String get NoNetworksFound {
    return Intl.message(
      'No networks found',
      name: 'NoNetworksFound',
      desc: '',
      args: [],
    );
  }

  /// `Connect`
  String get Connect {
    return Intl.message('Connect', name: 'Connect', desc: '', args: []);
  }

  /// `Bluetooth access is needed to change Wi-Fi settings.`
  String get offlineBlePermissionHint {
    return Intl.message(
      'Bluetooth access is needed to change Wi-Fi settings.',
      name: 'offlineBlePermissionHint',
      desc: '',
      args: [],
    );
  }

  /// `Move closer to the device to set up Wi-Fi.`
  String get offlineBleNotNearbyHint {
    return Intl.message(
      'Move closer to the device to set up Wi-Fi.',
      name: 'offlineBleNotNearbyHint',
      desc: '',
      args: [],
    );
  }

  /// `Device is offline`
  String get deviceOfflineTitle {
    return Intl.message(
      'Device is offline',
      name: 'deviceOfflineTitle',
      desc: '',
      args: [],
    );
  }

  /// `Last seen online: {lastSeenAt}`
  String deviceOfflineSubtitleWithLastSeen(Object lastSeenAt) {
    return Intl.message(
      'Last seen online: $lastSeenAt',
      name: 'deviceOfflineSubtitleWithLastSeen',
      desc: '',
      args: [lastSeenAt],
    );
  }

  /// `Move closer to the device to set up Wi-Fi over Bluetooth.`
  String get deviceOfflineHintBluetooth {
    return Intl.message(
      'Move closer to the device to set up Wi-Fi over Bluetooth.',
      name: 'deviceOfflineHintBluetooth',
      desc: '',
      args: [],
    );
  }

  /// `Connecting to device…`
  String get bleConnectingToDevice {
    return Intl.message(
      'Connecting to device…',
      name: 'bleConnectingToDevice',
      desc: '',
      args: [],
    );
  }

  /// `Device connected to Wi-Fi`
  String get deviceConnectedToWifi {
    return Intl.message(
      'Device connected to Wi-Fi',
      name: 'deviceConnectedToWifi',
      desc: '',
      args: [],
    );
  }

  /// `Failed to connect to Wi-Fi`
  String get wifiConnectFailed {
    return Intl.message(
      'Failed to connect to Wi-Fi',
      name: 'wifiConnectFailed',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get About {
    return Intl.message('About', name: 'About', desc: '', args: []);
  }

  /// `Discard`
  String get Discard {
    return Intl.message('Discard', name: 'Discard', desc: '', args: []);
  }

  /// `Unsaved changes`
  String get UnsavedChanges {
    return Intl.message(
      'Unsaved changes',
      name: 'UnsavedChanges',
      desc: '',
      args: [],
    );
  }

  /// `You have unsaved changes. Do you want to discard them and leave this page?`
  String get UnsavedChangesDiscardPrompt {
    return Intl.message(
      'You have unsaved changes. Do you want to discard them and leave this page?',
      name: 'UnsavedChangesDiscardPrompt',
      desc: '',
      args: [],
    );
  }

  /// `This device does not expose any settings yet.`
  String get DeviceNoSettingsYet {
    return Intl.message(
      'This device does not expose any settings yet.',
      name: 'DeviceNoSettingsYet',
      desc: '',
      args: [],
    );
  }

  /// `Device seems offline or not responding.`
  String get DeviceOfflineOrNotResponding {
    return Intl.message(
      'Device seems offline or not responding.',
      name: 'DeviceOfflineOrNotResponding',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load settings.`
  String get FailedToLoadSettings {
    return Intl.message(
      'Failed to load settings.',
      name: 'FailedToLoadSettings',
      desc: '',
      args: [],
    );
  }

  /// `No data yet`
  String get NoDataYet {
    return Intl.message('No data yet', name: 'NoDataYet', desc: '', args: []);
  }

  /// `Empty payload`
  String get EmptyPayload {
    return Intl.message(
      'Empty payload',
      name: 'EmptyPayload',
      desc: '',
      args: [],
    );
  }

  /// `Day`
  String get TelemetryHistoryRangeDay {
    return Intl.message(
      'Day',
      name: 'TelemetryHistoryRangeDay',
      desc: '',
      args: [],
    );
  }

  /// `Week`
  String get TelemetryHistoryRangeWeek {
    return Intl.message(
      'Week',
      name: 'TelemetryHistoryRangeWeek',
      desc: '',
      args: [],
    );
  }

  /// `Month`
  String get TelemetryHistoryRangeMonth {
    return Intl.message(
      'Month',
      name: 'TelemetryHistoryRangeMonth',
      desc: '',
      args: [],
    );
  }

  /// `Year`
  String get TelemetryHistoryRangeYear {
    return Intl.message(
      'Year',
      name: 'TelemetryHistoryRangeYear',
      desc: '',
      args: [],
    );
  }

  /// `Minimum`
  String get TelemetryHistoryStatMin {
    return Intl.message(
      'Minimum',
      name: 'TelemetryHistoryStatMin',
      desc: '',
      args: [],
    );
  }

  /// `Maximum`
  String get TelemetryHistoryStatMax {
    return Intl.message(
      'Maximum',
      name: 'TelemetryHistoryStatMax',
      desc: '',
      args: [],
    );
  }

  /// `Average`
  String get TelemetryHistoryStatAvg {
    return Intl.message(
      'Average',
      name: 'TelemetryHistoryStatAvg',
      desc: '',
      args: [],
    );
  }

  /// `Temperature sensor`
  String get TelemetryHistorySensorLabel {
    return Intl.message(
      'Temperature sensor',
      name: 'TelemetryHistorySensorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sensor {index}/{total}`
  String TelemetryHistorySensorPosition(Object index, Object total) {
    return Intl.message(
      'Sensor $index/$total',
      name: 'TelemetryHistorySensorPosition',
      desc: '',
      args: [index, total],
    );
  }

  /// `Failed to load chart`
  String get TelemetryHistoryLoadFailed {
    return Intl.message(
      'Failed to load chart',
      name: 'TelemetryHistoryLoadFailed',
      desc: '',
      args: [],
    );
  }

  /// `No data yet.`
  String get TelemetryHistoryNoData {
    return Intl.message(
      'No data yet.',
      name: 'TelemetryHistoryNoData',
      desc: '',
      args: [],
    );
  }

  /// `Load factor`
  String get TelemetryHistoryMetricLoadFactor {
    return Intl.message(
      'Load factor',
      name: 'TelemetryHistoryMetricLoadFactor',
      desc: '',
      args: [],
    );
  }

  /// `Heating activity`
  String get TelemetryHistoryMetricHeatingActivity {
    return Intl.message(
      'Heating activity',
      name: 'TelemetryHistoryMetricHeatingActivity',
      desc: '',
      args: [],
    );
  }

  /// `Temperature`
  String get TelemetryHistoryMetricTemperature {
    return Intl.message(
      'Temperature',
      name: 'TelemetryHistoryMetricTemperature',
      desc: '',
      args: [],
    );
  }

  /// `Target`
  String get TelemetryHistoryMetricTarget {
    return Intl.message(
      'Target',
      name: 'TelemetryHistoryMetricTarget',
      desc: '',
      args: [],
    );
  }

  /// `Temperature trend (24h)`
  String get TelemetryHistoryPreviewTitle24h {
    return Intl.message(
      'Temperature trend (24h)',
      name: 'TelemetryHistoryPreviewTitle24h',
      desc: '',
      args: [],
    );
  }

  /// `Temperature trend (24h): no sensor data`
  String get TelemetryHistoryPreviewNoSensorData {
    return Intl.message(
      'Temperature trend (24h): no sensor data',
      name: 'TelemetryHistoryPreviewNoSensorData',
      desc: '',
      args: [],
    );
  }

  /// `Open history`
  String get TelemetryHistoryPreviewOpenAction {
    return Intl.message(
      'Open history',
      name: 'TelemetryHistoryPreviewOpenAction',
      desc: '',
      args: [],
    );
  }

  /// `Open detailed temperature history.`
  String get TelemetryHistoryPreviewOpenHint {
    return Intl.message(
      'Open detailed temperature history.',
      name: 'TelemetryHistoryPreviewOpenHint',
      desc: '',
      args: [],
    );
  }

  /// `Resolution: {resolution} • Points: {points}`
  String TelemetryHistoryResolutionPoints(Object resolution, Object points) {
    return Intl.message(
      'Resolution: $resolution • Points: $points',
      name: 'TelemetryHistoryResolutionPoints',
      desc: '',
      args: [resolution, points],
    );
  }

  /// `Device scope is not available in the current context.`
  String get DeviceScopeUnavailableInContext {
    return Intl.message(
      'Device scope is not available in the current context.',
      name: 'DeviceScopeUnavailableInContext',
      desc: '',
      args: [],
    );
  }

  /// `Checking internet connection...`
  String get startupCheckingInternet {
    return Intl.message(
      'Checking internet connection...',
      name: 'startupCheckingInternet',
      desc: '',
      args: [],
    );
  }

  /// `Checking app version policy...`
  String get startupCheckingAppVersion {
    return Intl.message(
      'Checking app version policy...',
      name: 'startupCheckingAppVersion',
      desc: '',
      args: [],
    );
  }

  /// `No internet connection screen`
  String get startupNoInternetScreenSemantics {
    return Intl.message(
      'No internet connection screen',
      name: 'startupNoInternetScreenSemantics',
      desc: '',
      args: [],
    );
  }

  /// `No internet connection`
  String get startupNoInternetTitle {
    return Intl.message(
      'No internet connection',
      name: 'startupNoInternetTitle',
      desc: '',
      args: [],
    );
  }

  /// `Connect to Wi-Fi or mobile data to continue using Oshhome.`
  String get startupNoInternetSubtitle {
    return Intl.message(
      'Connect to Wi-Fi or mobile data to continue using Oshhome.',
      name: 'startupNoInternetSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Check that your network is available.`
  String get startupNoInternetHintNetwork {
    return Intl.message(
      'Check that your network is available.',
      name: 'startupNoInternetHintNetwork',
      desc: '',
      args: [],
    );
  }

  /// `If needed, reconnect and tap Retry.`
  String get startupNoInternetHintRetry {
    return Intl.message(
      'If needed, reconnect and tap Retry.',
      name: 'startupNoInternetHintRetry',
      desc: '',
      args: [],
    );
  }

  /// `App update recommendation dialog`
  String get startupUpdateRecommendSemantics {
    return Intl.message(
      'App update recommendation dialog',
      name: 'startupUpdateRecommendSemantics',
      desc: '',
      args: [],
    );
  }

  /// `A new app version is available`
  String get startupUpdateRecommendTitle {
    return Intl.message(
      'A new app version is available',
      name: 'startupUpdateRecommendTitle',
      desc: '',
      args: [],
    );
  }

  /// `Update to get the latest fixes and improvements.`
  String get startupUpdateRecommendSubtitle {
    return Intl.message(
      'Update to get the latest fixes and improvements.',
      name: 'startupUpdateRecommendSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Update now`
  String get startupUpdateNow {
    return Intl.message(
      'Update now',
      name: 'startupUpdateNow',
      desc: '',
      args: [],
    );
  }

  /// `Later`
  String get startupUpdateLater {
    return Intl.message(
      'Later',
      name: 'startupUpdateLater',
      desc: '',
      args: [],
    );
  }

  /// `App update required screen`
  String get startupUpdateRequiredSemantics {
    return Intl.message(
      'App update required screen',
      name: 'startupUpdateRequiredSemantics',
      desc: '',
      args: [],
    );
  }

  /// `Update app to continue`
  String get startupUpdateRequiredTitle {
    return Intl.message(
      'Update app to continue',
      name: 'startupUpdateRequiredTitle',
      desc: '',
      args: [],
    );
  }

  /// `This version is no longer supported. Install the latest version to keep using Oshhome.`
  String get startupUpdateRequiredSubtitle {
    return Intl.message(
      'This version is no longer supported. Install the latest version to keep using Oshhome.',
      name: 'startupUpdateRequiredSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Updating`
  String get MqttStatusUpdating {
    return Intl.message(
      'Updating',
      name: 'MqttStatusUpdating',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get MqttStatusError {
    return Intl.message('Error', name: 'MqttStatusError', desc: '', args: []);
  }

  /// `Last update: {time}`
  String LastUpdateAt(Object time) {
    return Intl.message(
      'Last update: $time',
      name: 'LastUpdateAt',
      desc: '',
      args: [time],
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
