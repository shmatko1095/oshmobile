// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(length) =>
      "Password must be at least ${length} characters long";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "AddDevice": MessageLookupByLibrary.simpleMessage("Add device"),
        "Cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "CheckYourEmail":
            MessageLookupByLibrary.simpleMessage("Check your email"),
        "ContinueWithGoogle":
            MessageLookupByLibrary.simpleMessage("Continue with Google"),
        "DeviceDetails": MessageLookupByLibrary.simpleMessage("Device details"),
        "DeviceEditTitle":
            MessageLookupByLibrary.simpleMessage("Device information"),
        "DeviceUnlinkAlertContent1":
            MessageLookupByLibrary.simpleMessage("The device "),
        "DeviceUnlinkAlertContent2": MessageLookupByLibrary.simpleMessage(
            " will be removed from your list. You can re-add it anytime by scanning the QR code again."),
        "Done": MessageLookupByLibrary.simpleMessage("Done"),
        "DontHaveAnAccount":
            MessageLookupByLibrary.simpleMessage("Don\'t have an account?"),
        "Email": MessageLookupByLibrary.simpleMessage("Email"),
        "Failed": MessageLookupByLibrary.simpleMessage("Failed"),
        "ForgotPassword":
            MessageLookupByLibrary.simpleMessage("Forgot password?"),
        "ForgotPasswordContent": MessageLookupByLibrary.simpleMessage(
            "Enter your email address, and we’ll send you a link to reset your password. It’s quick and secure."),
        "ForgotYourPassword":
            MessageLookupByLibrary.simpleMessage("Forgot your password"),
        "GoToLogin": MessageLookupByLibrary.simpleMessage("Go to Login"),
        "InvalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Invalid email address"),
        "InvalidPassword": m0,
        "InvalidUserCredentials":
            MessageLookupByLibrary.simpleMessage("Invalid user credentials"),
        "InvalidValue": MessageLookupByLibrary.simpleMessage("Invalid value"),
        "Name": MessageLookupByLibrary.simpleMessage("Name"),
        "No": MessageLookupByLibrary.simpleMessage("No"),
        "NoDeviceSelected":
            MessageLookupByLibrary.simpleMessage("No device selected"),
        "NoDevicesYet": MessageLookupByLibrary.simpleMessage("No devices yet"),
        "OK": MessageLookupByLibrary.simpleMessage("OK"),
        "Offline": MessageLookupByLibrary.simpleMessage("Offline"),
        "Online": MessageLookupByLibrary.simpleMessage("Online"),
        "Password": MessageLookupByLibrary.simpleMessage("Password"),
        "PasswordConfirmation":
            MessageLookupByLibrary.simpleMessage("Password confirmation"),
        "PasswordsDoNotMatch":
            MessageLookupByLibrary.simpleMessage("Passwords do not match"),
        "PleaseCheckYourInbox": MessageLookupByLibrary.simpleMessage(
            ". Please check your inbox and follow the instructions to complete your registration."),
        "PointCameraToQR": MessageLookupByLibrary.simpleMessage(
            "Point the camera at the QR code"),
        "RegistrationSuccessful":
            MessageLookupByLibrary.simpleMessage("Almost There!"),
        "RegistrationSuccessfulContent": MessageLookupByLibrary.simpleMessage(
            "The last step is to verify your email address. Please check your inbox and follow the instructions to complete your registration."),
        "ResetPassword": MessageLookupByLibrary.simpleMessage("Reset password"),
        "Room": MessageLookupByLibrary.simpleMessage("Room"),
        "SecureCode": MessageLookupByLibrary.simpleMessage("Secure code"),
        "SendEmail": MessageLookupByLibrary.simpleMessage("Send email"),
        "SerialNumber": MessageLookupByLibrary.simpleMessage("Serial number"),
        "Settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "SignIn": MessageLookupByLibrary.simpleMessage("Sign In"),
        "SignOut": MessageLookupByLibrary.simpleMessage("Sign Out"),
        "SignUp": MessageLookupByLibrary.simpleMessage("Sign Up"),
        "Successful": MessageLookupByLibrary.simpleMessage("Successful"),
        "TipCheckNetwork": MessageLookupByLibrary.simpleMessage(
            "Check the device\'s network connection."),
        "TipContactSupport": MessageLookupByLibrary.simpleMessage(
            "Contact support and provide the Model ID and Device ID."),
        "TipEnsureAppUpdated": MessageLookupByLibrary.simpleMessage(
            "Make sure the app is updated to the latest version."),
        "Tips": MessageLookupByLibrary.simpleMessage("Tips"),
        "TryDemo": MessageLookupByLibrary.simpleMessage("Try Demo"),
        "UnknownDeviceType":
            MessageLookupByLibrary.simpleMessage("Unknown device type"),
        "UnknownError": MessageLookupByLibrary.simpleMessage("Unknown error"),
        "UnlinkDevice": MessageLookupByLibrary.simpleMessage("Unlink Device"),
        "UnsupportedDeviceMessage": MessageLookupByLibrary.simpleMessage(
            "This device model is not yet supported by the current version of the app. You can try refreshing the data, opening the device settings, or sending a report."),
        "Update": MessageLookupByLibrary.simpleMessage("Update"),
        "UserAlreadyExist":
            MessageLookupByLibrary.simpleMessage("User already exist"),
        "VerifyYourEmail":
            MessageLookupByLibrary.simpleMessage("Verify your email"),
        "WeHaveSentVerificationEmailTo": MessageLookupByLibrary.simpleMessage(
            "We have sent a verification email to "),
        "Yes": MessageLookupByLibrary.simpleMessage("Yes"),
        "YourEmailIsNotVerifiedYet": MessageLookupByLibrary.simpleMessage(
            "Your email is not verified yet. Click the button below to resend the verification email.")
      };
}
