final class OshAnalyticsEvents {
  OshAnalyticsEvents._();

  static const authSignInSucceeded = 'auth_sign_in_succeeded';
  static const authSignInFailed = 'auth_sign_in_failed';
  static const authSignUpSucceeded = 'auth_sign_up_succeeded';
  static const authPasswordResetRequested = 'auth_password_reset_requested';
  static const authSignedOut = 'auth_signed_out';

  static const deviceListLoaded = 'device_list_loaded';
  static const deviceSelected = 'device_selected';
  static const deviceDashboardOpened = 'device_dashboard_opened';
  static const deviceAssignStarted = 'device_assign_started';
  static const deviceAssignSucceeded = 'device_assign_succeeded';
  static const deviceAssignFailed = 'device_assign_failed';
  static const deviceRenameSaved = 'device_rename_saved';
  static const deviceUnassigned = 'device_unassigned';

  static const bleProvisionStarted = 'ble_provision_started';
  static const bleNearbyCheckFailed = 'ble_nearby_check_failed';
  static const bleConnectSucceeded = 'ble_connect_succeeded';
  static const bleConnectFailed = 'ble_connect_failed';
  static const bleWifiNetworkSelected = 'ble_wifi_network_selected';
  static const bleWifiConnectSucceeded = 'ble_wifi_connect_succeeded';
  static const bleWifiConnectFailed = 'ble_wifi_connect_failed';

  static const deviceSettingsOpened = 'device_settings_opened';
  static const deviceSettingsSaved = 'device_settings_saved';
  static const deviceAboutOpened = 'device_about_opened';
  static const telemetryHistoryOpened = 'telemetry_history_opened';

  static const scheduleEditorOpened = 'schedule_editor_opened';
  static const scheduleSaved = 'schedule_saved';
  static const scheduleModeSelected = 'schedule_mode_selected';
  static const scheduleModeChanged = 'schedule_mode_changed';
  static const schedulePointAdded = 'schedule_point_added';
  static const schedulePointRemoved = 'schedule_point_removed';

  static const accountSettingsOpened = 'account_settings_opened';
  static const themeChanged = 'theme_changed';
  static const accountDeletionRequested = 'account_deletion_requested';

  static const mobilePolicyFetched = 'mobile_policy_fetched';
  static const mobilePolicyPromptShown = 'mobile_policy_prompt_shown';
  static const mobilePolicyUpdateTapped = 'mobile_policy_update_tapped';
  static const mobilePolicyLaterTapped = 'mobile_policy_later_tapped';
  static const mobilePolicyFallbackCache = 'mobile_policy_fallback_cache';
  static const mobilePolicyFailOpen = 'mobile_policy_fail_open';
}
