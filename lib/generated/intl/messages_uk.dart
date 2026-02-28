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

  static String m1(time) => "Останнє оновлення: ${time}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "About": MessageLookupByLibrary.simpleMessage("Про пристрій"),
    "DeviceNoSettingsYet": MessageLookupByLibrary.simpleMessage(
      "Цей пристрій поки що не має доступних налаштувань.",
    ),
    "DeviceOfflineOrNotResponding": MessageLookupByLibrary.simpleMessage(
      "Схоже, пристрій офлайн або не відповідає.",
    ),
    "Discard": MessageLookupByLibrary.simpleMessage("Скасувати зміни"),
    "EmptyPayload": MessageLookupByLibrary.simpleMessage("Порожні дані"),
    "FailedToLoadSettings": MessageLookupByLibrary.simpleMessage(
      "Не вдалося завантажити налаштування.",
    ),
    "LastUpdateAt": m1,
    "NoDataYet": MessageLookupByLibrary.simpleMessage("Дані ще не надійшли"),
    "Retry": MessageLookupByLibrary.simpleMessage("Спробувати знову"),
    "UnsavedChanges": MessageLookupByLibrary.simpleMessage("Незбережені зміни"),
    "UnsavedChangesDiscardPrompt": MessageLookupByLibrary.simpleMessage(
      "У вас є незбережені зміни. Скасувати їх і вийти зі сторінки?",
    ),
    "compatibilityErrorBadge": MessageLookupByLibrary.simpleMessage(
      "Помилка сумісності",
    ),
    "compatibilityErrorStepCheckConnection": MessageLookupByLibrary.simpleMessage(
      "Переконайтеся, що пристрій онлайн і backend bootstrap contract доступний.",
    ),
    "compatibilityErrorStepContactSupport": MessageLookupByLibrary.simpleMessage(
      "Якщо проблема не зникає, зверніться в підтримку та додайте серійний номер, Model ID і технічні деталі нижче.",
    ),
    "compatibilityErrorStepRetry": MessageLookupByLibrary.simpleMessage(
      "Спробуйте ще раз після повторного підключення пристрою або усунення проблеми сумісності на backend.",
    ),
    "compatibilityErrorSubtitle": MessageLookupByLibrary.simpleMessage(
      "Застосунку зараз не вдалося узгодити сумісний протокольний контракт для цього пристрою.",
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
    "updateAppRequiredBadge": MessageLookupByLibrary.simpleMessage(
      "Потрібне оновлення",
    ),
    "updateAppRequiredStepContactSupport": MessageLookupByLibrary.simpleMessage(
      "Якщо проблема залишиться після оновлення, зверніться в підтримку та вкажіть серійний номер і Model ID.",
    ),
    "updateAppRequiredStepReopen": MessageLookupByLibrary.simpleMessage(
      "Відкрийте пристрій знову після завершення оновлення та повторного підключення сесії.",
    ),
    "updateAppRequiredStepUpdate": MessageLookupByLibrary.simpleMessage(
      "Оновіть застосунок до останньої доступної версії на цьому пристрої.",
    ),
    "updateAppRequiredSubtitle": MessageLookupByLibrary.simpleMessage(
      "Цей пристрій використовує обов’язкові домени протоколу, які новіші за ті, що підтримує поточна версія застосунку.",
    ),
    "updateAppRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "Оновіть застосунок, щоб продовжити",
    ),
  };
}
