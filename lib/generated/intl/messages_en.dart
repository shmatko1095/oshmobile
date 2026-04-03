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

  static String m0(email) =>
      "We sent a confirmation email to ${email}. Open it and confirm account deletion.";

  static String m1(min, max) =>
      "First name must be between ${min} and ${max} characters";

  static String m2(min, max) =>
      "Last name must be between ${min} and ${max} characters";

  static String m3(length) =>
      "Password must be at least ${length} characters long";

  static String m4(time) => "Last update: ${time}";

  static String m5(temp, time) => "Next ${temp} at ${time}";

  static String m6(current, total) => "Step ${current} of ${total}";

  static String m7(temp) => "Target ${temp}";

  static String m8(resolution, points) =>
      "Resolution: ${resolution} • Points: ${points}";

  static String m9(index, total) => "Sensor ${index}/${total}";

  static String m10(lastSeenAt) => "Last seen online: ${lastSeenAt}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "About": MessageLookupByLibrary.simpleMessage("About"),
    "Account": MessageLookupByLibrary.simpleMessage("Account"),
    "AccountSettings": MessageLookupByLibrary.simpleMessage("Account settings"),
    "AddDevice": MessageLookupByLibrary.simpleMessage("Add device"),
    "ApplicationSettings": MessageLookupByLibrary.simpleMessage(
      "Application settings",
    ),
    "Back": MessageLookupByLibrary.simpleMessage("Back"),
    "Cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "CheckYourEmail": MessageLookupByLibrary.simpleMessage("Check your email"),
    "ChooseWiFi": MessageLookupByLibrary.simpleMessage("Choose Wi-Fi"),
    "ChooseWifiToConnect": MessageLookupByLibrary.simpleMessage(
      "Choose the wifi network you want to connect your device.",
    ),
    "Connect": MessageLookupByLibrary.simpleMessage("Connect"),
    "ContinueWithGoogle": MessageLookupByLibrary.simpleMessage(
      "Continue with Google",
    ),
    "Delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "DeleteAccount": MessageLookupByLibrary.simpleMessage("Delete account"),
    "DeleteAccountConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "This action is permanent and cannot be undone.",
    ),
    "DeleteAccountConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Delete account?",
    ),
    "DeleteAccountDescription": MessageLookupByLibrary.simpleMessage(
      "Permanently remove your account and all associated data.",
    ),
    "DeleteAccountEmailFlowDescription": MessageLookupByLibrary.simpleMessage(
      "For your security, we’ll send a confirmation email. Your account stays active until you confirm deletion in your inbox.",
    ),
    "DeleteAccountEmailFlowPendingNote": MessageLookupByLibrary.simpleMessage(
      "After you confirm from email, your account and related data will be scheduled for deletion.",
    ),
    "DeleteAccountEmailFlowSendButton": MessageLookupByLibrary.simpleMessage(
      "Send confirmation email",
    ),
    "DeleteAccountEmailFlowSuccessDescription": m0,
    "DeleteAccountEmailFlowSuccessHint": MessageLookupByLibrary.simpleMessage(
      "Didn’t request this? You can safely ignore this email.",
    ),
    "DeleteAccountEmailFlowTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm account deletion",
    ),
    "DeleteSensor": MessageLookupByLibrary.simpleMessage("Delete sensor"),
    "Deleted": MessageLookupByLibrary.simpleMessage("Deleted"),
    "DeviceDetails": MessageLookupByLibrary.simpleMessage("Device details"),
    "DeviceEditTitle": MessageLookupByLibrary.simpleMessage(
      "Device information",
    ),
    "DeviceNoSettingsYet": MessageLookupByLibrary.simpleMessage(
      "This device does not expose any settings yet.",
    ),
    "DeviceOfflineOrNotResponding": MessageLookupByLibrary.simpleMessage(
      "Device seems offline or not responding.",
    ),
    "DeviceScopeUnavailableInContext": MessageLookupByLibrary.simpleMessage(
      "Device scope is not available in the current context.",
    ),
    "DeviceUnlinkAlertContent1": MessageLookupByLibrary.simpleMessage(
      "The device ",
    ),
    "DeviceUnlinkAlertContent2": MessageLookupByLibrary.simpleMessage(
      " will be removed from your list. You can re-add it anytime by scanning the QR code again.",
    ),
    "Discard": MessageLookupByLibrary.simpleMessage("Discard"),
    "Done": MessageLookupByLibrary.simpleMessage("Done"),
    "DontHaveAnAccount": MessageLookupByLibrary.simpleMessage(
      "Don\'t have an account?",
    ),
    "Email": MessageLookupByLibrary.simpleMessage("Email"),
    "EmptyPayload": MessageLookupByLibrary.simpleMessage("Empty payload"),
    "Failed": MessageLookupByLibrary.simpleMessage("Failed"),
    "FailedToLoadSettings": MessageLookupByLibrary.simpleMessage(
      "Failed to load settings.",
    ),
    "FirstName": MessageLookupByLibrary.simpleMessage("First name"),
    "ForgotPassword": MessageLookupByLibrary.simpleMessage("Forgot password?"),
    "ForgotPasswordContent": MessageLookupByLibrary.simpleMessage(
      "Enter your email address, and we’ll send you a link to reset your password. It’s quick and secure.",
    ),
    "ForgotYourPassword": MessageLookupByLibrary.simpleMessage(
      "Forgot your password",
    ),
    "FriShort": MessageLookupByLibrary.simpleMessage("Fri"),
    "GoToLogin": MessageLookupByLibrary.simpleMessage("Go to Login"),
    "Heating": MessageLookupByLibrary.simpleMessage("Heating"),
    "InvalidEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Invalid email address",
    ),
    "InvalidFirstName": m1,
    "InvalidLastName": m2,
    "InvalidPassword": m3,
    "InvalidUserCredentials": MessageLookupByLibrary.simpleMessage(
      "Invalid user credentials",
    ),
    "InvalidValue": MessageLookupByLibrary.simpleMessage("Invalid value"),
    "LastName": MessageLookupByLibrary.simpleMessage("Last name"),
    "LastUpdateAt": m4,
    "ManualTemperature": MessageLookupByLibrary.simpleMessage(
      "Manual temperature",
    ),
    "ModeDaily": MessageLookupByLibrary.simpleMessage("Daily"),
    "ModeOff": MessageLookupByLibrary.simpleMessage("Off"),
    "ModeOn": MessageLookupByLibrary.simpleMessage("On"),
    "ModeRange": MessageLookupByLibrary.simpleMessage("Range"),
    "ModeWeekly": MessageLookupByLibrary.simpleMessage("Weekly"),
    "MonShort": MessageLookupByLibrary.simpleMessage("Mon"),
    "Name": MessageLookupByLibrary.simpleMessage("Name"),
    "Next": MessageLookupByLibrary.simpleMessage("Next"),
    "NextAt": m5,
    "No": MessageLookupByLibrary.simpleMessage("No"),
    "NoDataYet": MessageLookupByLibrary.simpleMessage("No data yet"),
    "NoDeviceSelected": MessageLookupByLibrary.simpleMessage(
      "No device selected",
    ),
    "NoDevicesYet": MessageLookupByLibrary.simpleMessage("No devices yet"),
    "NoNetworksFound": MessageLookupByLibrary.simpleMessage(
      "No networks found",
    ),
    "OK": MessageLookupByLibrary.simpleMessage("OK"),
    "Offline": MessageLookupByLibrary.simpleMessage("Offline"),
    "Online": MessageLookupByLibrary.simpleMessage("Online"),
    "Password": MessageLookupByLibrary.simpleMessage("Password"),
    "PasswordConfirmation": MessageLookupByLibrary.simpleMessage(
      "Password confirmation",
    ),
    "PasswordsDoNotMatch": MessageLookupByLibrary.simpleMessage(
      "Passwords do not match",
    ),
    "PleaseCheckYourInbox": MessageLookupByLibrary.simpleMessage(
      ". Please check your inbox and follow the instructions to complete your registration.",
    ),
    "PointCameraToQR": MessageLookupByLibrary.simpleMessage(
      "Point the camera at the QR code",
    ),
    "ProfileAndSettings": MessageLookupByLibrary.simpleMessage(
      "Profile & settings",
    ),
    "RegistrationSuccessful": MessageLookupByLibrary.simpleMessage(
      "Almost There!",
    ),
    "RegistrationSuccessfulContent": MessageLookupByLibrary.simpleMessage(
      "The last step is to verify your email address. Please check your inbox and follow the instructions to complete your registration.",
    ),
    "ResetPassword": MessageLookupByLibrary.simpleMessage("Reset password"),
    "Retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "Room": MessageLookupByLibrary.simpleMessage("Room"),
    "SatShort": MessageLookupByLibrary.simpleMessage("Sat"),
    "Save": MessageLookupByLibrary.simpleMessage("Save"),
    "Search": MessageLookupByLibrary.simpleMessage("Search"),
    "SecureCode": MessageLookupByLibrary.simpleMessage("Secure code"),
    "SendEmail": MessageLookupByLibrary.simpleMessage("Send email"),
    "SensorCalibration": MessageLookupByLibrary.simpleMessage("Calibration"),
    "SensorConditions": MessageLookupByLibrary.simpleMessage(
      "Sensor conditions",
    ),
    "SensorMainLabel": MessageLookupByLibrary.simpleMessage("Main"),
    "SensorMakeMain": MessageLookupByLibrary.simpleMessage("Make main sensor"),
    "SensorMoreActions": MessageLookupByLibrary.simpleMessage("Sensor actions"),
    "SensorNameHint": MessageLookupByLibrary.simpleMessage("Sensor name"),
    "SensorRename": MessageLookupByLibrary.simpleMessage("Rename sensor"),
    "SerialNumber": MessageLookupByLibrary.simpleMessage("Serial number"),
    "SetTemperature": MessageLookupByLibrary.simpleMessage("Set temperature"),
    "Settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "SignIn": MessageLookupByLibrary.simpleMessage("Sign In"),
    "SignOut": MessageLookupByLibrary.simpleMessage("Sign Out"),
    "SignUp": MessageLookupByLibrary.simpleMessage("Sign Up"),
    "StepOf": m6,
    "Successful": MessageLookupByLibrary.simpleMessage("Successful"),
    "SunShort": MessageLookupByLibrary.simpleMessage("Sun"),
    "Target": m7,
    "TelemetryHistoryLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to load chart",
    ),
    "TelemetryHistoryMetricHeatingActivity":
        MessageLookupByLibrary.simpleMessage("Heating activity"),
    "TelemetryHistoryMetricLoadFactor": MessageLookupByLibrary.simpleMessage(
      "Load factor",
    ),
    "TelemetryHistoryMetricTarget": MessageLookupByLibrary.simpleMessage(
      "Target",
    ),
    "TelemetryHistoryMetricTemperature": MessageLookupByLibrary.simpleMessage(
      "Temperature",
    ),
    "TelemetryHistoryNoData": MessageLookupByLibrary.simpleMessage(
      "No data yet.",
    ),
    "TelemetryHistoryPreviewNoSensorData": MessageLookupByLibrary.simpleMessage(
      "Temperature trend (24h): no sensor data",
    ),
    "TelemetryHistoryPreviewTitle24h": MessageLookupByLibrary.simpleMessage(
      "Temperature trend (24h)",
    ),
    "TelemetryHistoryRangeDay": MessageLookupByLibrary.simpleMessage("Day"),
    "TelemetryHistoryRangeMonth": MessageLookupByLibrary.simpleMessage("Month"),
    "TelemetryHistoryRangeWeek": MessageLookupByLibrary.simpleMessage("Week"),
    "TelemetryHistoryRangeYear": MessageLookupByLibrary.simpleMessage("Year"),
    "TelemetryHistoryResolutionPoints": m8,
    "TelemetryHistorySensorLabel": MessageLookupByLibrary.simpleMessage(
      "Temperature sensor",
    ),
    "TelemetryHistorySensorPosition": m9,
    "TelemetryHistoryStatAvg": MessageLookupByLibrary.simpleMessage("Average"),
    "TelemetryHistoryStatMax": MessageLookupByLibrary.simpleMessage("Maximum"),
    "TelemetryHistoryStatMin": MessageLookupByLibrary.simpleMessage("Minimum"),
    "ThemeDark": MessageLookupByLibrary.simpleMessage("Dark"),
    "ThemeLight": MessageLookupByLibrary.simpleMessage("Light"),
    "ThemeSystem": MessageLookupByLibrary.simpleMessage("System"),
    "ThuShort": MessageLookupByLibrary.simpleMessage("Thu"),
    "TipCheckNetwork": MessageLookupByLibrary.simpleMessage(
      "Check the device\'s network connection.",
    ),
    "TipContactSupport": MessageLookupByLibrary.simpleMessage(
      "Contact support and provide the Model ID and Device ID.",
    ),
    "TipEnsureAppUpdated": MessageLookupByLibrary.simpleMessage(
      "Make sure the app is updated to the latest version.",
    ),
    "Tips": MessageLookupByLibrary.simpleMessage("Tips"),
    "TryDemo": MessageLookupByLibrary.simpleMessage("Try Demo"),
    "TueShort": MessageLookupByLibrary.simpleMessage("Tue"),
    "Undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "UnknownDeviceType": MessageLookupByLibrary.simpleMessage(
      "Unknown device type",
    ),
    "UnknownError": MessageLookupByLibrary.simpleMessage("Unknown error"),
    "UnlinkDevice": MessageLookupByLibrary.simpleMessage("Unlink Device"),
    "UnsavedChanges": MessageLookupByLibrary.simpleMessage("Unsaved changes"),
    "UnsavedChangesDiscardPrompt": MessageLookupByLibrary.simpleMessage(
      "You have unsaved changes. Do you want to discard them and leave this page?",
    ),
    "UnsupportedDeviceMessage": MessageLookupByLibrary.simpleMessage(
      "This device model is not yet supported by the current version of the app. You can try refreshing the data, opening the device settings, or sending a report.",
    ),
    "Update": MessageLookupByLibrary.simpleMessage("Update"),
    "UserAlreadyExist": MessageLookupByLibrary.simpleMessage(
      "User already exist",
    ),
    "VerifyYourEmail": MessageLookupByLibrary.simpleMessage(
      "Verify your email",
    ),
    "WeHaveSentVerificationEmailTo": MessageLookupByLibrary.simpleMessage(
      "We have sent a verification email to ",
    ),
    "WedShort": MessageLookupByLibrary.simpleMessage("Wed"),
    "Yes": MessageLookupByLibrary.simpleMessage("Yes"),
    "YourEmailIsNotVerifiedYet": MessageLookupByLibrary.simpleMessage(
      "Your email is not verified yet. Click the button below to resend the verification email.",
    ),
    "bleConnectingToDevice": MessageLookupByLibrary.simpleMessage(
      "Connecting to device…",
    ),
    "compatibilityErrorBadge": MessageLookupByLibrary.simpleMessage(
      "Compatibility error",
    ),
    "compatibilityErrorStepCheckConnection": MessageLookupByLibrary.simpleMessage(
      "Make sure the device is online and the backend bootstrap contract is available.",
    ),
    "compatibilityErrorStepContactSupport": MessageLookupByLibrary.simpleMessage(
      "If it keeps failing, contact support with the serial number, model ID, and the technical details below.",
    ),
    "compatibilityErrorStepRetry": MessageLookupByLibrary.simpleMessage(
      "Retry after the device reconnects or the backend compatibility issue is resolved.",
    ),
    "compatibilityErrorSubtitle": MessageLookupByLibrary.simpleMessage(
      "The app could not establish a compatible protocol contract for this device right now.",
    ),
    "compatibilityErrorTitle": MessageLookupByLibrary.simpleMessage(
      "This device cannot be opened",
    ),
    "compatibilityNextStepsTitle": MessageLookupByLibrary.simpleMessage(
      "What to do next",
    ),
    "compatibilityTechnicalDetailsTitle": MessageLookupByLibrary.simpleMessage(
      "Technical details",
    ),
    "control": MessageLookupByLibrary.simpleMessage("Heating control"),
    "controlModel": MessageLookupByLibrary.simpleMessage("Control model"),
    "deviceConnectedToWifi": MessageLookupByLibrary.simpleMessage(
      "Device connected to Wi-Fi",
    ),
    "deviceOfflineHintBluetooth": MessageLookupByLibrary.simpleMessage(
      "Move closer to the device to set up Wi-Fi over Bluetooth.",
    ),
    "deviceOfflineSubtitleWithLastSeen": m10,
    "deviceOfflineTitle": MessageLookupByLibrary.simpleMessage(
      "Device is offline",
    ),
    "display": MessageLookupByLibrary.simpleMessage("Display"),
    "displayActiveBrightness": MessageLookupByLibrary.simpleMessage(
      "Active brightness",
    ),
    "displayDimOnIdle": MessageLookupByLibrary.simpleMessage("Dim on idle"),
    "displayIdleBrightness": MessageLookupByLibrary.simpleMessage(
      "Idle brightness",
    ),
    "displayIdleTime": MessageLookupByLibrary.simpleMessage("Idle dim timeout"),
    "displayLanguage": MessageLookupByLibrary.simpleMessage("Language"),
    "maxFloorTempFailSafe": MessageLookupByLibrary.simpleMessage(
      "Floor sensor fail-safe",
    ),
    "maxFloorTempLimitEnabled": MessageLookupByLibrary.simpleMessage(
      "Floor temperature limit",
    ),
    "maxFloorTemperature": MessageLookupByLibrary.simpleMessage(
      "Max floor temperature",
    ),
    "offlineBleNotNearbyHint": MessageLookupByLibrary.simpleMessage(
      "Move closer to the device to set up Wi-Fi.",
    ),
    "offlineBlePermissionHint": MessageLookupByLibrary.simpleMessage(
      "Bluetooth access is needed to change Wi-Fi settings.",
    ),
    "startupCheckingInternet": MessageLookupByLibrary.simpleMessage(
      "Checking internet connection...",
    ),
    "startupNoInternetHintNetwork": MessageLookupByLibrary.simpleMessage(
      "Check that your network is available.",
    ),
    "startupNoInternetHintRetry": MessageLookupByLibrary.simpleMessage(
      "If needed, reconnect and tap Retry.",
    ),
    "startupNoInternetScreenSemantics": MessageLookupByLibrary.simpleMessage(
      "No internet connection screen",
    ),
    "startupNoInternetSubtitle": MessageLookupByLibrary.simpleMessage(
      "Connect to Wi-Fi or mobile data to continue using Oshhome.",
    ),
    "startupNoInternetTitle": MessageLookupByLibrary.simpleMessage(
      "No internet connection",
    ),
    "time": MessageLookupByLibrary.simpleMessage("Time"),
    "timeAuto": MessageLookupByLibrary.simpleMessage("Automatic time"),
    "timeZone": MessageLookupByLibrary.simpleMessage("Time zone"),
    "updateAppRequiredBadge": MessageLookupByLibrary.simpleMessage(
      "Update required",
    ),
    "updateAppRequiredStepContactSupport": MessageLookupByLibrary.simpleMessage(
      "If the issue remains after updating, contact support and include the serial number and model ID.",
    ),
    "updateAppRequiredStepReopen": MessageLookupByLibrary.simpleMessage(
      "Open the device again after the update finishes and the session reconnects.",
    ),
    "updateAppRequiredStepUpdate": MessageLookupByLibrary.simpleMessage(
      "Update the app to the latest available version on this device.",
    ),
    "updateAppRequiredSubtitle": MessageLookupByLibrary.simpleMessage(
      "This device uses required protocol domains that are newer than the current app build supports.",
    ),
    "updateAppRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "Update app to continue",
    ),
    "updateAtMidnight": MessageLookupByLibrary.simpleMessage(
      "Update at midnight",
    ),
    "updateAutoUpdateEnabled": MessageLookupByLibrary.simpleMessage(
      "Auto update",
    ),
    "updates": MessageLookupByLibrary.simpleMessage("Updates"),
    "wifiConnectFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to connect to Wi-Fi",
    ),
  };
}
