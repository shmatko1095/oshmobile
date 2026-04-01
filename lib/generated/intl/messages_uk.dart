// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a uk locale. All the
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
  String get localeName => 'uk';

  static String m0(length) =>
      "Пароль має містити щонайменше ${length} символів";

  static String m1(time) => "Останнє оновлення: ${time}";

  static String m2(temp, time) => "Наступне ${temp} о ${time}";

  static String m3(temp) => "Ціль ${temp}";

  static String m4(resolution, points) =>
      "Роздільність: ${resolution} • Точки: ${points}";

  static String m5(index, total) => "Датчик ${index}/${total}";

  static String m6(lastSeenAt) => "Востаннє був онлайн: ${lastSeenAt}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "About": MessageLookupByLibrary.simpleMessage("Про пристрій"),
    "AddDevice": MessageLookupByLibrary.simpleMessage("Додати пристрій"),
    "Cancel": MessageLookupByLibrary.simpleMessage("Скасувати"),
    "CheckYourEmail": MessageLookupByLibrary.simpleMessage("Перевірте пошту"),
    "ChooseWiFi": MessageLookupByLibrary.simpleMessage("Вибрати Wi‑Fi"),
    "ChooseWifiToConnect": MessageLookupByLibrary.simpleMessage(
      "Виберіть мережу Wi‑Fi, до якої потрібно підключити пристрій.",
    ),
    "Connect": MessageLookupByLibrary.simpleMessage("Підключити"),
    "ContinueWithGoogle": MessageLookupByLibrary.simpleMessage(
      "Продовжити з Google",
    ),
    "DeleteSensor": MessageLookupByLibrary.simpleMessage("Видалити датчик"),
    "Deleted": MessageLookupByLibrary.simpleMessage("Видалено"),
    "DeviceDetails": MessageLookupByLibrary.simpleMessage("Деталі пристрою"),
    "DeviceEditTitle": MessageLookupByLibrary.simpleMessage(
      "Інформація про пристрій",
    ),
    "DeviceNoSettingsYet": MessageLookupByLibrary.simpleMessage(
      "Цей пристрій поки що не має доступних налаштувань.",
    ),
    "DeviceOfflineOrNotResponding": MessageLookupByLibrary.simpleMessage(
      "Схоже, пристрій офлайн або не відповідає.",
    ),
    "DeviceScopeUnavailableInContext": MessageLookupByLibrary.simpleMessage(
      "Контекст пристрою недоступний у поточному місці.",
    ),
    "DeviceUnlinkAlertContent1": MessageLookupByLibrary.simpleMessage(
      "Пристрій ",
    ),
    "DeviceUnlinkAlertContent2": MessageLookupByLibrary.simpleMessage(
      " буде видалено з вашого списку. Ви зможете додати його знову, відсканувавши QR-код.",
    ),
    "Discard": MessageLookupByLibrary.simpleMessage("Скасувати зміни"),
    "Done": MessageLookupByLibrary.simpleMessage("Готово"),
    "DontHaveAnAccount": MessageLookupByLibrary.simpleMessage(
      "Ще немає облікового запису?",
    ),
    "Email": MessageLookupByLibrary.simpleMessage("Email"),
    "EmptyPayload": MessageLookupByLibrary.simpleMessage("Порожні дані"),
    "Failed": MessageLookupByLibrary.simpleMessage("Не вдалося"),
    "FailedToLoadSettings": MessageLookupByLibrary.simpleMessage(
      "Не вдалося завантажити налаштування.",
    ),
    "ForgotPassword": MessageLookupByLibrary.simpleMessage("Забули пароль?"),
    "ForgotPasswordContent": MessageLookupByLibrary.simpleMessage(
      "Введіть email, і ми надішлемо посилання для скидання пароля. Це швидко й безпечно.",
    ),
    "ForgotYourPassword": MessageLookupByLibrary.simpleMessage("Забули пароль"),
    "FriShort": MessageLookupByLibrary.simpleMessage("Пт"),
    "GoToLogin": MessageLookupByLibrary.simpleMessage("Перейти до входу"),
    "Heating": MessageLookupByLibrary.simpleMessage("Нагрів"),
    "InvalidEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Неправильна email-адреса",
    ),
    "InvalidPassword": m0,
    "InvalidUserCredentials": MessageLookupByLibrary.simpleMessage(
      "Неправильний email або пароль",
    ),
    "InvalidValue": MessageLookupByLibrary.simpleMessage("Недійсне значення"),
    "LastUpdateAt": m1,
    "ManualTemperature": MessageLookupByLibrary.simpleMessage(
      "Ручна температура",
    ),
    "ModeDaily": MessageLookupByLibrary.simpleMessage("Щоденно"),
    "ModeOff": MessageLookupByLibrary.simpleMessage("Вимкн."),
    "ModeOn": MessageLookupByLibrary.simpleMessage("Увімкн."),
    "ModeRange": MessageLookupByLibrary.simpleMessage("Діапазон"),
    "ModeWeekly": MessageLookupByLibrary.simpleMessage("Щотижня"),
    "MonShort": MessageLookupByLibrary.simpleMessage("Пн"),
    "Name": MessageLookupByLibrary.simpleMessage("Назва"),
    "NextAt": m2,
    "No": MessageLookupByLibrary.simpleMessage("Ні"),
    "NoDataYet": MessageLookupByLibrary.simpleMessage("Дані ще не надійшли"),
    "NoDeviceSelected": MessageLookupByLibrary.simpleMessage(
      "Пристрій не вибрано",
    ),
    "NoDevicesYet": MessageLookupByLibrary.simpleMessage("Пристроїв ще немає"),
    "NoNetworksFound": MessageLookupByLibrary.simpleMessage(
      "Мереж не знайдено",
    ),
    "OK": MessageLookupByLibrary.simpleMessage("OK"),
    "Offline": MessageLookupByLibrary.simpleMessage("Офлайн"),
    "Online": MessageLookupByLibrary.simpleMessage("Онлайн"),
    "Password": MessageLookupByLibrary.simpleMessage("Пароль"),
    "PasswordConfirmation": MessageLookupByLibrary.simpleMessage(
      "Підтвердження пароля",
    ),
    "PasswordsDoNotMatch": MessageLookupByLibrary.simpleMessage(
      "Паролі не збігаються",
    ),
    "PleaseCheckYourInbox": MessageLookupByLibrary.simpleMessage(
      ". Перевірте вхідні та виконайте інструкції, щоб завершити реєстрацію.",
    ),
    "PointCameraToQR": MessageLookupByLibrary.simpleMessage(
      "Наведіть камеру на QR-код",
    ),
    "RegistrationSuccessful": MessageLookupByLibrary.simpleMessage(
      "Майже готово!",
    ),
    "RegistrationSuccessfulContent": MessageLookupByLibrary.simpleMessage(
      "Останній крок — підтвердіть email. Перевірте вхідні та виконайте інструкції, щоб завершити реєстрацію.",
    ),
    "ResetPassword": MessageLookupByLibrary.simpleMessage("Скинути пароль"),
    "Retry": MessageLookupByLibrary.simpleMessage("Спробувати знову"),
    "Room": MessageLookupByLibrary.simpleMessage("Кімната"),
    "SatShort": MessageLookupByLibrary.simpleMessage("Сб"),
    "Save": MessageLookupByLibrary.simpleMessage("Зберегти"),
    "Search": MessageLookupByLibrary.simpleMessage("Пошук"),
    "SecureCode": MessageLookupByLibrary.simpleMessage("Захисний код"),
    "SendEmail": MessageLookupByLibrary.simpleMessage("Надіслати лист"),
    "SensorCalibration": MessageLookupByLibrary.simpleMessage("Калібрування"),
    "SensorConditions": MessageLookupByLibrary.simpleMessage(
      "Показники датчика",
    ),
    "SensorMainLabel": MessageLookupByLibrary.simpleMessage("Основний"),
    "SensorMakeMain": MessageLookupByLibrary.simpleMessage("Зробити основним"),
    "SensorMoreActions": MessageLookupByLibrary.simpleMessage("Дії датчика"),
    "SensorNameHint": MessageLookupByLibrary.simpleMessage("Назва датчика"),
    "SensorRename": MessageLookupByLibrary.simpleMessage(
      "Перейменувати датчик",
    ),
    "SerialNumber": MessageLookupByLibrary.simpleMessage("Серійний номер"),
    "SetTemperature": MessageLookupByLibrary.simpleMessage(
      "Встановити температуру",
    ),
    "Settings": MessageLookupByLibrary.simpleMessage("Налаштування"),
    "SignIn": MessageLookupByLibrary.simpleMessage("Увійти"),
    "SignOut": MessageLookupByLibrary.simpleMessage("Вийти"),
    "SignUp": MessageLookupByLibrary.simpleMessage("Зареєструватися"),
    "Successful": MessageLookupByLibrary.simpleMessage("Успішно"),
    "SunShort": MessageLookupByLibrary.simpleMessage("Нд"),
    "Target": m3,
    "TelemetryHistoryLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Не вдалося завантажити графік",
    ),
    "TelemetryHistoryMetricHeatingActivity":
        MessageLookupByLibrary.simpleMessage("Активність нагріву"),
    "TelemetryHistoryMetricLoadFactor": MessageLookupByLibrary.simpleMessage(
      "Коефіцієнт навантаження",
    ),
    "TelemetryHistoryMetricTarget": MessageLookupByLibrary.simpleMessage(
      "Ціль",
    ),
    "TelemetryHistoryMetricTemperature": MessageLookupByLibrary.simpleMessage(
      "Температура",
    ),
    "TelemetryHistoryNoData": MessageLookupByLibrary.simpleMessage(
      "Даних ще немає.",
    ),
    "TelemetryHistoryPreviewNoSensorData": MessageLookupByLibrary.simpleMessage(
      "Історія температури (24 год): немає даних датчиків",
    ),
    "TelemetryHistoryPreviewTitle24h": MessageLookupByLibrary.simpleMessage(
      "Історія температури (24 год)",
    ),
    "TelemetryHistoryRangeDay": MessageLookupByLibrary.simpleMessage("День"),
    "TelemetryHistoryRangeMonth": MessageLookupByLibrary.simpleMessage(
      "Місяць",
    ),
    "TelemetryHistoryRangeWeek": MessageLookupByLibrary.simpleMessage(
      "Тиждень",
    ),
    "TelemetryHistoryRangeYear": MessageLookupByLibrary.simpleMessage("Рік"),
    "TelemetryHistoryResolutionPoints": m4,
    "TelemetryHistorySensorLabel": MessageLookupByLibrary.simpleMessage(
      "Температурний датчик",
    ),
    "TelemetryHistorySensorPosition": m5,
    "TelemetryHistoryStatAvg": MessageLookupByLibrary.simpleMessage("Середнє"),
    "TelemetryHistoryStatMax": MessageLookupByLibrary.simpleMessage("Максимум"),
    "TelemetryHistoryStatMin": MessageLookupByLibrary.simpleMessage("Мінімум"),
    "ThuShort": MessageLookupByLibrary.simpleMessage("Чт"),
    "TipCheckNetwork": MessageLookupByLibrary.simpleMessage(
      "Перевірте, чи підключено пристрій до Wi‑Fi.",
    ),
    "TipContactSupport": MessageLookupByLibrary.simpleMessage(
      "Зверніться в підтримку та вкажіть Model ID і Device ID.",
    ),
    "TipEnsureAppUpdated": MessageLookupByLibrary.simpleMessage(
      "Переконайтеся, що застосунок оновлено до останньої версії.",
    ),
    "Tips": MessageLookupByLibrary.simpleMessage("Поради"),
    "TryDemo": MessageLookupByLibrary.simpleMessage("Спробувати демо"),
    "TueShort": MessageLookupByLibrary.simpleMessage("Вт"),
    "Undo": MessageLookupByLibrary.simpleMessage("Скасувати"),
    "UnknownDeviceType": MessageLookupByLibrary.simpleMessage(
      "Невідомий тип пристрою",
    ),
    "UnknownError": MessageLookupByLibrary.simpleMessage(
      "Сталася невідома помилка",
    ),
    "UnlinkDevice": MessageLookupByLibrary.simpleMessage("Відвʼязати пристрій"),
    "UnsavedChanges": MessageLookupByLibrary.simpleMessage("Незбережені зміни"),
    "UnsavedChangesDiscardPrompt": MessageLookupByLibrary.simpleMessage(
      "У вас є незбережені зміни. Скасувати їх і вийти зі сторінки?",
    ),
    "UnsupportedDeviceMessage": MessageLookupByLibrary.simpleMessage(
      "Ця модель пристрою поки не підтримується поточною версією застосунку. Спробуйте оновити дані, відкрити налаштування пристрою або надіслати звіт.",
    ),
    "Update": MessageLookupByLibrary.simpleMessage("Оновити"),
    "UserAlreadyExist": MessageLookupByLibrary.simpleMessage(
      "Користувач уже існує",
    ),
    "VerifyYourEmail": MessageLookupByLibrary.simpleMessage(
      "Підтвердьте email",
    ),
    "WeHaveSentVerificationEmailTo": MessageLookupByLibrary.simpleMessage(
      "Ми надіслали лист для підтвердження на ",
    ),
    "WedShort": MessageLookupByLibrary.simpleMessage("Ср"),
    "Yes": MessageLookupByLibrary.simpleMessage("Так"),
    "YourEmailIsNotVerifiedYet": MessageLookupByLibrary.simpleMessage(
      "Ваш email ще не підтверджено. Натисніть кнопку нижче, щоб надіслати лист повторно.",
    ),
    "bleConnectingToDevice": MessageLookupByLibrary.simpleMessage(
      "Підключення до пристрою…",
    ),
    "compatibilityErrorBadge": MessageLookupByLibrary.simpleMessage(
      "Помилка сумісності",
    ),
    "compatibilityErrorStepCheckConnection": MessageLookupByLibrary.simpleMessage(
      "Переконайтеся, що пристрій онлайн і bootstrap-контракт бекенду доступний.",
    ),
    "compatibilityErrorStepContactSupport": MessageLookupByLibrary.simpleMessage(
      "Якщо проблема не зникає, зверніться в підтримку та додайте серійний номер, Model ID і технічні деталі нижче.",
    ),
    "compatibilityErrorStepRetry": MessageLookupByLibrary.simpleMessage(
      "Спробуйте ще раз після перепідключення пристрою або усунення проблеми сумісності на бекенді.",
    ),
    "compatibilityErrorSubtitle": MessageLookupByLibrary.simpleMessage(
      "Застосунку зараз не вдалося встановити сумісний протокольний контракт для цього пристрою.",
    ),
    "compatibilityErrorTitle": MessageLookupByLibrary.simpleMessage(
      "Не вдається відкрити пристрій",
    ),
    "compatibilityNextStepsTitle": MessageLookupByLibrary.simpleMessage(
      "Що робити далі",
    ),
    "compatibilityTechnicalDetailsTitle": MessageLookupByLibrary.simpleMessage(
      "Технічні деталі",
    ),
    "control": MessageLookupByLibrary.simpleMessage("Керування нагрівом"),
    "controlModel": MessageLookupByLibrary.simpleMessage("Модель керування"),
    "deviceConnectedToWifi": MessageLookupByLibrary.simpleMessage(
      "Пристрій підключено до Wi‑Fi",
    ),
    "deviceOfflineHintBluetooth": MessageLookupByLibrary.simpleMessage(
      "Наблизьтеся до пристрою, щоб налаштувати Wi‑Fi через Bluetooth.",
    ),
    "deviceOfflineSubtitleWithLastSeen": m6,
    "deviceOfflineTitle": MessageLookupByLibrary.simpleMessage(
      "Пристрій офлайн",
    ),
    "display": MessageLookupByLibrary.simpleMessage("Екран"),
    "displayActiveBrightness": MessageLookupByLibrary.simpleMessage(
      "Яскравість у роботі",
    ),
    "displayDimOnIdle": MessageLookupByLibrary.simpleMessage(
      "Затемнювати у простої",
    ),
    "displayIdleBrightness": MessageLookupByLibrary.simpleMessage(
      "Яскравість у простої",
    ),
    "displayIdleTime": MessageLookupByLibrary.simpleMessage(
      "Затримка затемнення",
    ),
    "displayLanguage": MessageLookupByLibrary.simpleMessage("Мова"),
    "maxFloorTempFailSafe": MessageLookupByLibrary.simpleMessage(
      "Аварійний режим датчика підлоги",
    ),
    "maxFloorTempLimitEnabled": MessageLookupByLibrary.simpleMessage(
      "Обмеження температури підлоги",
    ),
    "maxFloorTemperature": MessageLookupByLibrary.simpleMessage(
      "Макс. температура підлоги",
    ),
    "offlineBleNotNearbyHint": MessageLookupByLibrary.simpleMessage(
      "Підійдіть ближче до пристрою, щоб налаштувати Wi‑Fi.",
    ),
    "offlineBlePermissionHint": MessageLookupByLibrary.simpleMessage(
      "Щоб змінити налаштування Wi‑Fi, потрібен доступ до Bluetooth.",
    ),
    "startupCheckingInternet": MessageLookupByLibrary.simpleMessage(
      "Перевіряємо підключення до інтернету...",
    ),
    "startupNoInternetHintNetwork": MessageLookupByLibrary.simpleMessage(
      "Перевірте, чи доступна мережа.",
    ),
    "startupNoInternetHintRetry": MessageLookupByLibrary.simpleMessage(
      "За потреби перепідключіться і натисніть «Спробувати знову».",
    ),
    "startupNoInternetScreenSemantics": MessageLookupByLibrary.simpleMessage(
      "Екран без підключення до інтернету",
    ),
    "startupNoInternetSubtitle": MessageLookupByLibrary.simpleMessage(
      "Підключіться до Wi‑Fi або мобільного інтернету, щоб продовжити користуватися Oshhome.",
    ),
    "startupNoInternetTitle": MessageLookupByLibrary.simpleMessage(
      "Немає підключення до інтернету",
    ),
    "time": MessageLookupByLibrary.simpleMessage("Час"),
    "timeAuto": MessageLookupByLibrary.simpleMessage("Автоматичний час"),
    "timeZone": MessageLookupByLibrary.simpleMessage("Часовий пояс"),
    "updateAppRequiredBadge": MessageLookupByLibrary.simpleMessage(
      "Потрібне оновлення",
    ),
    "updateAppRequiredStepContactSupport": MessageLookupByLibrary.simpleMessage(
      "Якщо проблема не зникне після оновлення, зверніться в підтримку та вкажіть серійний номер і Model ID.",
    ),
    "updateAppRequiredStepReopen": MessageLookupByLibrary.simpleMessage(
      "Відкрийте пристрій знову після завершення оновлення та повторного підключення сесії.",
    ),
    "updateAppRequiredStepUpdate": MessageLookupByLibrary.simpleMessage(
      "Оновіть застосунок до останньої доступної версії на цьому пристрої.",
    ),
    "updateAppRequiredSubtitle": MessageLookupByLibrary.simpleMessage(
      "Цей пристрій використовує обовʼязкові домени протоколу, новіші за ті, що підтримує поточна версія застосунку.",
    ),
    "updateAppRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "Оновіть застосунок, щоб продовжити",
    ),
    "updateAtMidnight": MessageLookupByLibrary.simpleMessage(
      "Оновлювати опівночі",
    ),
    "updateAutoUpdateEnabled": MessageLookupByLibrary.simpleMessage(
      "Автооновлення",
    ),
    "updates": MessageLookupByLibrary.simpleMessage("Оновлення"),
    "wifiConnectFailed": MessageLookupByLibrary.simpleMessage(
      "Не вдалося підключитися до Wi‑Fi",
    ),
  };
}
