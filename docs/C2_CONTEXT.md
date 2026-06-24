# C2 — Контекст міжсесійний

> Цей файл — єдине джерело правди для сесій C2.1 → C2.2 → C2.3.
> Кожна сесія ПОЧИНАЄ з讀 цього файлу і ЗАПИСУЄ свій результат наприкінці.

## Статус

| Сесія | Завдання | Статус | DoD |
|-------|----------|--------|-----|
| C2.1 | jest fix + API types + Turnstile widget + layout | ✅ DONE | tsc → 0 errors, jest → 4/4 pass |
| C2.2 | Calculator page (3-step funnel) | ✅ DONE | tsc → 0 errors, build → success |
| C2.3 | Tests + CI + BUILD_LOG | ✅ DONE | npm test → all pass (11/11), tsc → 0 errors, build → success |

## Ключові файли

### Backend (НЕ чіпати — лише читати для довідки)
- `services/security-api/app/schemas/calculator.py` — CalcSubmitRequest/Response
- `services/security-api/app/routes/calculator.py` — POST /api/v2/calculator/submit

### Frontend (змінюються)
- `riad_web/src/lib/api.ts` — API client (axios instance з interceptor)
- `riad_web/src/app/layout.tsx` — Root layout (Server Component)
- `riad_web/src/app/page.tsx` — Головна сторінка
- `riad_web/jest.config.js` — Jest конфігурація (має помилку!)
- `riad_web/package.json` — Залежності (axios, @testing-library/react вже є)

### Нові файли (створюються)
- `riad_web/jest.setup.ts` — Jest setup
- `riad_web/src/types/turnstile.d.ts` — Turnstile типи
- `riad_web/src/components/TurnstileWidget.tsx` — Turnstile React компонент
- `riad_web/src/app/calculator/page.tsx` — Сторінка калькулятора
- `riad_web/__tests__/c2/calculator.test.tsx` — Тести

## Backend-схема (джерело правди для типів)

```python
# CalcSubmitRequest
object_type: str           # CCTV Analog / CCTV IP / Access Control / Alarm / Network / Mixed
area_m2: float             # gt=0
cameras_count: int         # ge=0
archive_days: int          # ge=0
contact_name: str
contact_phone: str
contact_email: str = ""
captcha_token: str

# CalcSubmitResponse
submission_name: str
estimated_total: float
matched_scenario: Optional[str] = None
status: str
```

## Env variables
- `NEXT_PUBLIC_TURNSTILE_SITEKEY` — sitekey для Cloudflare Turnstile (НЕ хардкодити)

## Патерни (з існуючого коду)
- axios mock для тестів: `riad_web/__tests__/s4/s4_screens.test.ts`
- Tailwind CSS: mobile-first
- Мова: українська
- Error codes: 429 (rate limit), 422 (captcha), 500/502 (backend down)

## Лог записів

### C2.1
- **Змінені файли:** `riad_web/jest.config.js`, `riad_web/src/lib/api.ts`, `riad_web/src/app/layout.tsx`
- **Нові файли:** `riad_web/jest.setup.ts`, `riad_web/src/types/turnstile.d.ts`, `riad_web/src/components/TurnstileWidget.tsx`
- **Додані devDeps:** `jest-environment-jsdom`, `@types/jest`
- **Помилка:** `setupFilesAfterSetup` → `setupFilesAfterEnv` (правильна назва ключа Jest 29)
- **Build:** warehouse/page має попередній баг QueryClientProvider — не пов'язано з C2.1

### C2.2
- **Створені файли:** `riad_web/src/app/calculator/page.tsx`
- **Змінені файли:** `riad_web/src/app/page.tsx` (додано посилання "Калькулятор")
- **Перевірки:** tsc --noEmit → 0 errors, npm run build → success
- **Примітки:** 3-крокова воронка (Параметри → Контакти → Результат), Turnstile CAPTCHA, error handling 429/422/500-502

### C2.3
- **Створені файли:** `riad_web/__tests__/c2/calculator.test.tsx`
- **Змінені файли:** `.github/workflows/ci.yml` (+C2 tsc/test/build кроки), `BUILD_LOG.md` (+C2 секція)
- **Перевірки:** tsc --noEmit → 0 errors, npm test → 11/11 pass, npm run build → success
- **Примітки:** 11 тестів через @testing-library/react, mock axios + TurnstileWidget + submitCalculator. Тест-покриття: step navigation, form validation, API payload, success/error states (429/502)
