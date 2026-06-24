# Промт E5-A1: Анонімізація fail-closed + людський gate

```
Прочитай CLAUDE.md і BUILD_LOG.md.

Ти — Python/FastAPI розробник. Виконай сесію E5-A1: анонімізація PII fail-closed + людський gate.

## Контекст

Проєкт Security ERP Platform. Існує AI-шар з Circuit Breaker, orchestrator, Gemini adapter.
Потрібно захистити PII перед зовнішнім AI. Fail-closed = помилка анонімізації → зовнішній виклик НЕ робиться.

## Існуючий код

- `services/security-api/app/services/ai_orchestrator_service.py` — `_anonymize_payload()` (базовий)
- `services/security-api/app/routes/ai.py` — `execute_ai()`, `get_providers_health()`
- `services/security-api/app/schemas/ai.py` — pydantic моделі
- `services/security-api/app/core/database.py` — `frappe_get/post/put`

## Що робимо

### Крок 1: Розширити `_anonymize_payload()` в `ai_orchestrator_service.py`

Додати regex-анонімізацію:
- Телефони: `\+380\d{9}`, `0\d{9}`, `\d{3}-\d{3}-\d{4}`
- Email: `[\w.-]+@[\w.-]+\.\w+`
- ІПН/ЄДРПОУ: `\d{10}` (ІПН), `\d{8}` (ЄДРПОУ)
- Імена: залишити як є (NER — defense-in-depth, не обов'язково)

Повертати:
```python
{
    "ok": True/False,  # False = знайдено PII яке не вдалося анонімізувати
    "payload": {...},  # анонімізовані дані
    "blocked_fields": [...]  # поля з невідомим PII
}
```

### Крок 2: Додати human gate endpoints в `ai.py`

```python
@router.post("/preview")
async def preview_anonymized(request: AIExecuteRequest, ...):
    """Показує анонімізований payload перед відправкою."""
    result = _anonymize_payload(request.task, request.payload)
    # Зберігаємо в Redis з TTL 5хв: ai:preview:{user_id}:{task_hash}
    return {"anonymized": result, "original_keys": list(request.payload.keys())}

@router.post("/approve")
async def approve_execution(request: AIApprovalRequest, ...):
    """Підтверджує відправку. Зберігає approval в Redis."""
    # Перевіряє що preview існує в Redis
    # Зберігає approval: ai:approved:{user_id}:{task_hash} = True, TTL 5хв
    return {"approved": True}
```

### Крок 3: Оновити `execute_ai()` з fail-closed логікою

```python
@router.post("/execute")
async def execute_ai(request: AIExecuteRequest, ...):
    anonymized = _anonymize_payload(request.task, request.payload)
    
    if not anonymized["ok"]:
        raise HTTPException(
            status_code=409,
            detail={
                "error": "pii_detected",
                "blocked_fields": anonymized["blocked_fields"],
                "message": "Виявлено PII яке не вдалося анонімізувати. Використовуйте manual mode.",
            }
        )
    
    # Далі — як раніше, з анонімізованим payload
    result = await frappe_post(...)
```

### Крок 4: Pydantic моделі в `schemas/ai.py`

Додати:
```python
class AIApprovalRequest(BaseModel):
    task: str
    payload: dict

class AIPreviewResponse(BaseModel):
    ok: bool
    payload: dict
    blocked_fields: list[str]
    original_keys: list[str]
```

### Крок 5: Тести в `tests/ai/test_a2_ai_service.py`

Додати тести:
- `test_anonymize_phones` — телефони анонімізуються
- `test_anonymize_emails` — email анонімізуються
- `test_anonymize_ipn` — ІПН/ЄДРПОУ анонімізуються
- `test_fail_closed` — невідомий PII → ok=False
- `test_preview_endpoint` — preview повертає анонімізовані дані
- `test_approve_endpoint` — approve зберігає в Redis
- `test_execute_fail_closed` — execute з PII → 409

## DoD (зупинись тут, не роби A2)

✅ `_anonymize_payload()` анонімізує телефони/email/ІПН/ЄДРПОУ
✅ Fail-closed: невідомий PII → ok=False → execute повертає 409
✅ Human gate: preview → approve → execute
✅ Тести проходять: `python -m pytest tests/ai/test_a2_ai_service.py -v`
✅ `flutter analyze` не застосовується (Python-only сесія)

## Заборони

- Не видаляй існуючий код — тільки додавай
- Не змінюй контракти існуючих endpoints
- Не коміть без явного дозволу
- Використовуй `logger` замість `print()`
- Відповідай українською мовою

Онови BUILD_LOG.md (секція E5-A1 з DoD-чеклістом) і запропонуй промт E5-A2 (Whisper self-hosted + RQ-задачі транскрипції).
```
