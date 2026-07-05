# Refactor Plan

## Цель

Улучшить поддерживаемость проекта без полного переписывания архитектуры. Текущая структура в целом удачная: feature-first модули, BLoC/Cubit, GetIt scopes, runtime configuration для устройств, отдельные session/device lifecycles. Рефактор нужен точечно вокруг крупных координаторов, DI и мест, где presentation слой знает слишком много об инфраструктуре.

## Прогресс 2026-07-05

Выполнено:

- `init_dependencies.dart` сокращен до composition root, который только задает порядок регистрации зависимостей.
- Core/bootstrap регистрации вынесены в `lib/core/di/core_dependencies.dart`.
- Feature registrations вынесены в отдельные `di` модули внутри features.
- `DeviceFacadeImpl` разгружен: построение `DeviceSnapshot` и `controlState` вынесено в `DeviceSnapshotBuilder`.
- Start/refresh/dispose orchestration для device domain APIs вынесен из `DeviceFacadeImpl` в `DeviceDomainApiCoordinator`.
- Для schedule/settings API добавлены общие helpers: stream с текущим значением, timeout/error message mapper, best-effort cancel/close logging.
- В `DeviceFacadeImpl` silent catch для start/refresh/dispose заменен на best-effort logging через `AppLog` без изменения tolerant behavior.
- В ключевом lifecycle/start/refresh/dispose пути `app/device_session` silent catch заменен на best-effort logging через `AppLog`; оставшиеся `onError` paths переводят ошибки в slice state или defensive cleanup behavior.
- `AccountSettingsPage` переведен на constructor injection; locator оставлен только на route boundary.
- `TemperatureMinimalPanel`, `TemperatureHistoryStripCard`, `ThermostatModeBar` и `BleOfflineEntry` больше не читают зависимости напрямую из service locator.
- Availability update в `DeviceHostBody` вынесен из build phase в post-frame callback; `SelectedDeviceSessionCubit` больше не эмитит дубликаты availability state.

Проверено после follow-up фикса:

- `dart format --output=none --set-exit-if-changed` для Dart-файлов, измененных веткой.
- `flutter analyze`
- `flutter test --reporter compact`

## Главные Принципы

- Сохранять существующие публичные API и поведение экранов.
- Делать изменения маленькими шагами с тестами после каждого шага.
- Не смешивать рефактор с изменением продукта или UI-дизайна.
- Не ломать session/device GetIt scopes: MQTT-зависимости должны оставаться session-scoped или device-scoped.
- Для device dashboard продолжать читать live values из `DeviceSnapshot.controlState`.

## Приоритет 1: DI И Composition Root

Проблема: `lib/init_dependencies.dart` стал большим central registry файлом, в котором смешаны core, auth, device catalog, device management, device session, telemetry history и BLE.

План:

1. Создать feature-level registration helpers, например:
   - `AuthFeatureDi.register(GetIt locator)`
   - `DeviceCatalogFeatureDi.register(GetIt locator)`
   - `DeviceManagementFeatureDi.register(GetIt locator)`
   - `TelemetryHistoryFeatureDi.register(GetIt locator)`
   - `BleProvisioningFeatureDi.register(GetIt locator)`
2. Оставить в `initDependencies()` только порядок инициализации.
3. Не менять lifetime registrations за один раз: сначала только перенос кода, затем отдельные улучшения.

Проверка:

- `dart format` для затронутых файлов.
- Точечные тесты auth/device catalog/startup, если доступны.
- `flutter analyze` и `flutter test`, когда Flutter SDK доступен в PATH.

## Приоритет 2: Уменьшить Прямое Использование Locator В Presentation

Проблема: часть страниц и виджетов напрямую вызывает `locator` или `GetIt`, из-за чего UI становится труднее тестировать и переиспользовать.

План:

1. Начать с route/page boundaries, где зависимости можно подать через `BlocProvider`, `RepositoryProvider` или конструктор.
2. Перенести получение зависимостей из внутренних widgets/presenters наружу.
3. Оставить `locator` допустимым только в DI/bootstrap/route composition слоях.

Кандидаты:

- `lib/features/account_settings/presentation/pages/account_settings_page.dart`
- presenter widgets в `lib/features/devices/details/presentation/presenters/widgets/`
- navigation/open helper файлы, если они создают cubits напрямую

Проверка:

- Widget tests для измененных страниц.
- Проверить, что navigation flows не потеряли нужные providers.

## Приоритет 3: Разгрузить DeviceFacade

Проблема: `DeviceFacadeImpl` полезен как граница, но уже выполняет слишком много ролей: orchestration, startup, refresh, snapshot build, settings schema build, control state resolution, error swallowing.

План:

1. Сохранить `DeviceFacade` как публичную границу для UI.
2. Вынести построение `DeviceSnapshot` в отдельный builder/coordinator.
3. Вынести запуск и refresh domain APIs в отдельный небольшой coordinator.
4. Оставить `DeviceFacadeImpl` тонким владельцем lifecycle и API accessors.

Проверка:

- Тесты вокруг `DeviceSnapshotCubit` и device dashboard presenters.
- Тесты `ControlStateResolver` и schedule/settings API.
- Ручная проверка переключения устройств и relogin, если есть dev-сборка.

## Приоритет 4: Общая Основа Для Device Slice APIs

Проблема: schedule/settings/telemetry/about APIs повторяют похожие механики: start/watch/get, base snapshot, local overrides, dirty/saving/error states, stream emission, serial execution, MQTT comm tracking.

План:

1. Не начинать с абстрактного generic base class для всего сразу.
2. Сначала выделить маленькие общие утилиты:
   - stream-with-current helper
   - dispose/cancel helper с логированием
   - common error message mapper
   - comm tracked operation helper
3. После 2-3 применений решить, нужен ли общий base class.

Кандидаты:

- `lib/app/device_session/data/apis/device_schedule_api_impl.dart`
- `lib/app/device_session/data/apis/device_settings_api_impl.dart`
- `lib/app/device_session/data/apis/device_telemetry_api_impl.dart`
- `lib/app/device_session/data/apis/device_about_api_impl.dart`

Проверка:

- `test/app/device_session/data/apis/device_schedule_api_impl_test.dart`
- новые unit tests для settings API dirty/save behavior перед крупным переносом

## Приоритет 5: Ошибки И Наблюдаемость

Проблема: в device/MQTT слоях много `catch (_) {}` и `onError: (_) {}`. Для IoT-приложения это опасно: деградация связи может исчезнуть без следа.

План:

1. Разделить ожидаемые cleanup failures и реальные runtime failures.
2. Для cleanup failures оставить best-effort, но добавить debug/non-fatal log с контекстом там, где это полезно.
3. Для stream/API failures передавать короткие user-safe ошибки в slice state, а технические детали в logging/crash context.
4. Не шуметь Crashlytics постоянными background disconnects.

Проверка:

- Unit tests для error state transitions.
- Ручная проверка offline/background/resume scenarios.

## Приоритет 6: Доменные Контракты И Transport Boundaries

Проблема: некоторые domain interfaces импортируют модели из `core/network/mqtt/protocol/v1`. Это смешивает доменную границу с transport namespace.

План:

1. Если эти модели являются стабильным device runtime contract, перенести или переэкспортировать их из более нейтрального пакета, например `core/contracts` или feature domain models.
2. Не менять JSON-RPC/MQTT codecs одновременно с переносом моделей.
3. Добавить mapping/adapters только там, где реально нужен разрыв transport/domain.

Кандидаты:

- `lib/features/devices/details/domain/repositories/telemetry_repository.dart`
- `lib/features/sensors/domain/repositories/sensors_repository.dart`

Проверка:

- MQTT repository tests.
- Sensors and telemetry presenter tests.

## Приоритет 7: Крупные UI Файлы

Проблема: несколько UI файлов стали слишком большими и смешивают layout, parsing, formatting, state decisions и interaction wiring.

Кандидаты:

- `lib/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart`
- `lib/features/telemetry_history/presentation/widgets/history_multi_line_chart.dart`
- `lib/features/schedule/presentation/pages/schedule_editor_page.dart`
- `lib/features/telemetry_history/presentation/models/telemetry_history_slide_view_model.dart`

План:

1. Выносить pure helpers/resolvers/view models первыми.
2. Не дробить layout на слишком мелкие widgets без повторного использования.
3. Покрывать behavior-focused widget tests перед переносом интерактивной логики.

Проверка:

- Существующие widget tests для temperature panel, thermostat mode bar, telemetry history widgets.
- Golden/screenshot tests можно добавить позже, если команда готова поддерживать их стабильно.

## Что Не Делать Сейчас

- Не переписывать state management с BLoC/GetIt на другой стек.
- Не убирать `DeviceFacade` полностью: он полезен как UI boundary.
- Не смешивать sensor calibration или новые product decisions с техническим рефактором.
- Не менять порядок `climateSensors` ради reference sensor. Carousel/page state должен двигаться к reference sensor без reorder данных.
- Не делать большой rename/move всех features за один PR.

## Рекомендуемый Порядок PR

1. DI split: механический перенос registration блоков из `init_dependencies.dart`.
2. Locator cleanup в одном-двух presentation entry points.
3. Logging cleanup для silent catch в device facade/API слоях.
4. Device slice helper extraction для schedule/settings.
5. `DeviceFacadeImpl` decomposition после появления helper APIs.
6. UI file decomposition для `temperature_minimal_panel` и telemetry charts.
7. Domain/transport namespace cleanup для MQTT protocol models.

## Минимальные Команды Проверки

```sh
dart format lib test
flutter analyze
flutter test --reporter compact
```

Если Flutter SDK недоступен в PATH, сначала починить локальное окружение. Без `flutter test` безопасный рефактор этого проекта будет заметно рискованнее.
