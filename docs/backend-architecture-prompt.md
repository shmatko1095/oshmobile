# Backend Architecture Prompt (OSH IoT)

## 1) Назначение документа
Этот документ содержит готовый промт для проектирования backend-архитектуры OSH IoT-платформы:
- ingestion телеметрии по MQTT от устройств;
- нормализация состояния внутри OSH;
- маппинг в интеграции (Google Cloud-to-Cloud, Home Assistant и др.);
- безопасная эволюция контрактов и полей.

---

## 2) Краткий контекст системы
- `OSH` = наше мобильное приложение + наш cloud backend.
- Устройство публикует JSON-RPC сообщения в MQTT (`state/*`, `evt/*`, `rsp`).
- Каждое устройство имеет `model_id`.
- Для каждого `model_id` есть `model config profile`.
- В профиле есть секции для разных интеграций:
  - `osh` (внутренний runtime/app/cloud),
  - `google` (Google C2C),
  - `ha` (Home Assistant),
  - и другие в будущем.

Пример входящего сообщения от устройства:

Topic:
`v1/tenants/devices-dev/devices/9C139EB205F0/state/telemetry`

Payload:
```json
{
  "jsonrpc": "2.0",
  "method": "telemetry.state",
  "params": {
    "meta": {
      "schema": "telemetry@1",
      "src": "device",
      "ts": 1772052894345
    },
    "data": {
      "climate_sensors": [
        {"id": "air", "temp_valid": false, "humidity_valid": false},
        {"id": "floor", "temp_valid": true, "humidity_valid": false, "temp": 22.63},
        {"id": "pcb", "temp_valid": true, "humidity_valid": false, "temp": 44.96},
        {"id": "chip", "temp_valid": true, "humidity_valid": false, "temp": 46.7}
      ],
      "heater_enabled": false,
      "load_factor": 60
    }
  }
}
```

---

## 3) Ключевая архитектурная идея
Не маппить device -> Google/HA напрямую в ingest-слое.

Правильная цепочка:
1. Device MQTT ingest.
2. Envelope/payload validation.
3. Raw event storage (audit/replay).
4. OSH normalization (внутренняя модель состояния).
5. Integration adapters (Google/HA/другие).

Это дает:
- стабильный внутренний слой OSH;
- легкое добавление новых интеграций;
- контролируемую эволюцию контрактов.

---

## 4) Что считать “каноническим” слоем
Важно: Google и HA имеют свои фиксированные поля/traits/entities.

Поэтому “канон” = не подмена Google-формата, а внутренний OSH semantic layer:
- OSH-ключи/смыслы (например `climate.target_temperature`, `climate.ambient_temperature`, `heater.state`);
- затем bindings в `osh/google/ha`.

Подход:
- интеграционно-специфичные поля остаются в соответствующих секциях;
- общий смысл связывается через semantic key и mapping-правила.

---

## 5) Принципы эволюции контрактов
1. `schema@major`:
- additive changes внутри major (новые optional поля);
- breaking changes только новым major (`@2`).
2. Mapper версии:
- отдельный parser/mapper под каждый major.
3. Unknown fields:
- логируем и метрим, но не роняем pipeline.
4. Deprecation policy:
- `deprecated_since`,
- `remove_in`,
- миграционный путь.

---

## 6) Структура model config profile (концепт)
Вариант структуры:
- `model_id`
- `profile_version`
- `capabilities`
- `contracts_supported`
- `semantics` (внутренние OSH ключи, типы, ограничения)
- `integrations`:
  - `osh` (topic/method/path rules, selection/fallback rules)
  - `google` (traits/states/commands mapping)
  - `ha` (entities/attributes/services mapping)

Пример критичного правила:
- выбор ambient temperature:
  - `primary_sensor_id = air`
  - `fallback = floor`
  - учитывать только `temp_valid = true`.

---

## 7) Нефункциональные требования
1. Масштабирование:
- ingestion sharding по tenant/device serial range;
- stateless workers + shared state store.
2. Надежность:
- at-least-once ingestion;
- idempotent projection/update;
- дедупликация по `(device, schema, ts, seq?)`.
3. Порядок событий:
- добавить `seq` в протокол (желательно);
- out-of-order handling policy.
4. Observability:
- metrics, structured logs, traces;
- per-device health and lag.
5. Безопасность:
- tenant isolation;
- ACL на MQTT topics;
- audit trail изменений.

---

## 8) Готовый промт для AI (копируй блок ниже)
```text
Ты Senior Backend Architect для IoT-платформы OSH.

Контекст:
- OSH = мобильное приложение + cloud backend.
- Устройства публикуют JSON-RPC over MQTT.
- Каждое устройство имеет model_id.
- Для каждого model_id существует model config profile.
- В profile есть секции интеграций: osh, google, ha.

Пример входящего сообщения:
Topic: v1/tenants/devices-dev/devices/9C139EB205F0/state/telemetry
Payload:
{
  "jsonrpc":"2.0",
  "method":"telemetry.state",
  "params":{
    "meta":{"schema":"telemetry@1","src":"device","ts":1772052894345},
    "data":{
      "climate_sensors":[
        {"id":"air","temp_valid":false,"humidity_valid":false},
        {"id":"floor","temp_valid":true,"humidity_valid":false,"temp":22.63},
        {"id":"pcb","temp_valid":true,"humidity_valid":false,"temp":44.96},
        {"id":"chip","temp_valid":true,"humidity_valid":false,"temp":46.7}
      ],
      "heater_enabled":false,
      "load_factor":60
    }
  }
}

Задача:
Спроектируй production-ready backend-архитектуру:
1) MQTT ingestion слой для всех устройств (с горизонтальным масштабированием).
2) Validation pipeline (envelope + payload schema validation).
3) Raw event storage для audit/replay.
4) Normalized OSH state layer (внутренний semantic слой).
5) Mapper/adapters из OSH state в:
   - Google Cloud-to-Cloud,
   - Home Assistant,
   - future integrations.

Требования:
- Не делать прямой mapping device->google в ingest.
- Интеграции должны читать нормализованное OSH состояние.
- Поддержать эволюцию контрактов telemetry@1, telemetry@2 и т.д.
- Additive changes внутри major, breaking changes через новый major.
- Неизвестные поля не должны ронять pipeline.
- Добавь стратегию дедупликации и out-of-order handling.
- Опиши необходимость seq и поведение при его отсутствии.
- Опиши cache strategy для device->model profile lookup.
- Опиши multi-tenant security boundaries и ACL.

Что выдать:
1) C4-like архитектурная схема (текстом: containers/components).
2) Подробный data flow: from MQTT message to integration update.
3) Структуру model config profile (JSON schema-level outline):
   - model_id, profile_version, capabilities, contracts_supported,
   - semantics,
   - integrations.osh/google/ha.
4) Пример mapping rules:
   - ambient temperature selection: primary sensor + fallback + valid flags.
5) Versioning policy и migration strategy.
6) API/contracts между сервисами.
7) План observability (metrics/logs/traces/SLOs).
8) Тест-стратегию:
   - contract tests,
   - mapper tests,
   - replay tests,
   - chaos/failure tests.
9) Пошаговый rollout plan (MVP -> production hardening).

Формат ответа:
- максимально практично;
- с четкими интерфейсами между сервисами;
- с рисками, trade-offs и mitigations;
- без абстрактной воды.
```

---

## 9) Дополнительный чеклист перед реализацией backend
1. Утвердить JSON Schema для каждого `schema@major`.
2. Утвердить формат `model config profile` и versioning policy.
3. Добавить `seq` в device protocol (если возможно).
4. Определить source-of-truth для `device -> model_id`.
5. Определить правила fallback для критичных semantic keys.
6. Задать SLO ingest latency и delivery latency для интеграций.
7. Определить стратегию replay/backfill.
