# Release Readiness Report — oshmobile

- Дата: 2026-04-22
- Версия приложения: `1.0.7+16`
- Ветка: `main` (синхронизирована с `origin/main`, working tree clean)

## Общий вердикт

**Почти готов, но есть блокеры.** Качество кода и тесты в хорошем состоянии, но перед публикацией в сторы нужно закрыть конфигурационные и подписные проблемы (см. раздел «Критичные блокеры»).

## Автоматические проверки

| Проверка | Результат |
|---|---|
| `flutter analyze` | **No issues found** |
| `flutter test` | **89/89 passed** |
| Git status | clean, на `origin/main` |

## Критичные блокеры (должно быть исправлено до релиза)

### 1. Keycloak указывает на DEV-realm
Файл: [lib/core/secrets/app_secrets.dart](lib/core/secrets/app_secrets.dart#L3)

```
https://auth.oshhome.com/realms/users-dev/protocol/openid-connect/token
```

Для релиза необходим prod-realm (например `users`). Иначе все пользователи будут аутентифицироваться в dev-окружении.

### 2. `clientSecret` захардкожен в открытом исходнике
Файл: [lib/core/secrets/app_secrets.dart](lib/core/secrets/app_secrets.dart#L4)

Для публичного мобильного клиента Keycloak этот «секрет» по факту не является секретом, но хранить DEV-креды в репозитории не следует. Рекомендуется:
- перевести клиента в Keycloak на public + PKCE без секрета, **или**
- подставлять значения через `--dart-define` в release-сборках, а dev-значение убрать из исходников.

### 3. Отсутствует `android/key.properties`
Файл конфигурации подписи: [android/app/build.gradle](android/app/build.gradle#L12)

`key.properties` ожидается, но отсутствует. Без него `flutter build appbundle --release` соберёт **неподписанный** AAB, который Google Play не примет. Нужно подготовить upload keystore и `key.properties` на билд-машине/в CI (не коммитить).

### 4. Дубликат ключа в `Info.plist`
Файл: [ios/Runner/Info.plist](ios/Runner/Info.plist#L49-L52)

`NSCameraUsageDescription` объявлен дважды (первый — про фото, второй — про QR). iOS возьмёт последний, но это предупреждение при проверке App Store. Оставить одну корректную формулировку.

## Некритичные замечания (рекомендуется закрыть)

- **TODO в релизном коде**
  - [lib/features/devices/details/presentation/presenters/device_offline_page.dart](lib/features/devices/details/presentation/presenters/device_offline_page.dart#L51) — `secureCodeStub = 'TODO_SECURE_CODE'`
  - [lib/features/auth/data/repositories/auth_repository_impl.dart](lib/features/auth/data/repositories/auth_repository_impl.dart#L156) — комментарий `TODO: call your backend here`
- **README.md** — дефолтный шаблон Flutter, нет описания проекта, инструкций по сборке и релизу.
- **Android `buildTypes.release`** — не включены `minifyEnabled` / `shrinkResources` / ProGuard. Для Flutter допустимо, но включение уменьшит AAB и даст минимум защиты ресурсов.
- **`print` / `debugPrint` в `lib/`** — 15 вхождений. В релизе `debugPrint` становится no-op, но стоит пересмотреть логирование на предмет возможной утечки чувствительных данных.
- **`lib/device_mock/`** — MQTT thermostat mock с `localhost` ([main_mock.dart](lib/device_mock/main_mock.dart#L6)). Убедиться, что этот entrypoint не собирается в релизный билд.
- **`supports-screens` в AndroidManifest** — [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml#L8-L12) содержит `largeScreens="false"` и `xlargeScreens="false"`. Это скрывает приложение на планшетах в Google Play. Если поддержка планшетов планируется — исправить.
- **iOS orientations** — в [Info.plist](ios/Runner/Info.plist#L29-L45) разрешены landscape-ориентации, но код принудительно ставит `portraitUp`. Убрать landscape из plist, чтобы App Store Review не требовал landscape-скриншоты.
- **Нет flavors/конфигурационной схемы для dev/prod** — ввести `--dart-define` или flavors для `baseUrl`, `realm`, `clientSecret`, уровня логирования.

## Что в порядке

- Firebase Core / Crashlytics / Analytics инициализируются корректно, есть fatal/non-fatal сплит, защита от рекурсивных падений репортёра ([lib/main.dart](lib/main.dart#L43-L68)).
- Mobile client policy v1 (force/recommend update) реализован и задокументирован — см. [docd/mobile-client-policy-plan.md](docd/mobile-client-policy-plan.md).
- Локализация: `en` + `uk` через `intl_utils`.
- Secure storage, JWT decode, BLE provisioning, QR-сканер, permission_handler — подключены и имеют usage description (кроме дубля выше).
- Архитектура: feature-based, DI через `get_it`, Bloc/Cubit, сетевой слой на `chopper` c интерсептором `X-App-*` заголовков.
- Тесты покрывают: analytics, crash reporter, MQTT repositories / JSON-RPC, валидаторы форм, headers interceptor, startup/policy — все зелёные.

## Конфигурация платформ (факты)

- Android application id: `com.oshmobile.oshmobile`
- Android namespace: `com.oshmobile.oshmobile`
- Android manifest permissions: INTERNET, BLUETOOTH, BLUETOOTH_ADMIN, ACCESS_FINE_LOCATION, BLUETOOTH_SCAN, BLUETOOTH_CONNECT
- iOS bundle id: `com.oshmobile.oshmobile`
- iOS usage descriptions: Photo library, Camera (дубль), Bluetooth Always / Peripheral, Location When In Use
- Firebase project id: `osh-mobile-2c3c6`
- Supported locales: `en`, `uk`

## Чеклист перед публикацией

1. [ ] Переключить Keycloak realm и clientSecret на prod (через `--dart-define` / flavors).
2. [ ] Подготовить upload keystore и `android/key.properties` в CI (не коммитить).
3. [ ] Убрать дубль `NSCameraUsageDescription` в `ios/Runner/Info.plist`.
4. [ ] Устранить `TODO_SECURE_CODE` в `device_offline_page.dart` и TODO в `auth_repository_impl.dart`.
5. [ ] Принять решение по `largeScreens` / `xlargeScreens` в AndroidManifest.
6. [ ] Привести iOS orientations в `Info.plist` в соответствие с реальным поведением (portrait only).
7. [ ] Обновить `README.md` и подготовить release notes для `1.0.7`.
8. [ ] Проверить отсутствие `lib/device_mock/main_mock.dart` в release entrypoint.
9. [ ] Рассмотреть включение `minifyEnabled` / `shrinkResources` для Android release.
10. [ ] Прогнать `flutter build appbundle --release` и `flutter build ipa --release` на чистой машине, проверить размер, подпись, запуск на реальном устройстве.
11. [ ] Проверить mobile client policy (`/v1/mobile/client-policy`) на prod-окружении для текущей версии.

## Итог

Код и тесты в хорошей форме, функционал v1 готов. В **текущем** виде выкладывать в Google Play / App Store нельзя — минимально необходимо: переключить auth на prod, подписать Android-билд, поправить `Info.plist`. После закрытия блокеров проект готов к релизу.
