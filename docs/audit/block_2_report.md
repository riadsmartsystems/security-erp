# Block 2 Audit Report — `services/security-api/app/`

**Date:** 2026-06-23
**Scope:** Import resolution, route shadowing, dead code, unused imports, route conflicts
**Methodology:** Systematic file-by-file analysis of all routes/, services/, schemas/, main.py, auth/, core/

---

## 1. Import Resolution Failures

### 1.1 `security_erp.*` imports unreachable from security-api container

| File:Line | Import | Status | Reason |
|-----------|--------|--------|--------|
| `routes/ai.py:40` | `from security_erp.ai.adapters.gemini import GeminiAdapter` | ❌ BROKEN | `security_erp` not on PYTHONPATH in security-api container (only in `Dockerfile.backend`) |
| `routes/ai.py:41` | `from security_erp.ai.adapters.stub import StubAdapter` | ❌ BROKEN | Same |
| `routes/ai.py:42` | `from security_erp.ai.circuit_breaker import CircuitBreaker` | ❌ BROKEN | Same |
| `routes/ai.py:43` | `from security_erp.ai.orchestrator import AIOrchestrator` | ❌ BROKEN | Same |

**Note:** These are lazy imports inside `_build_orchestrator()` function, so they only fail at runtime when `POST /api/v2/ai/execute` is called. The module itself loads without error.

### 1.2 Circular / cross-layer import violation

| File:Line | Import | Status | Reason |
|-----------|--------|--------|--------|
| `services/estimate_service.py:57` | `from app.routes.ai import _build_orchestrator` | ⚠️ VIOLATION | Service imports from routes layer (R4 violation). Also circular dependency risk: `estimates.py` → `estimate_service.py` → `routes/ai.py`. |

### 1.3 All other imports — RESOLVED ✅

All imports in the following files resolve correctly against the codebase:

- **routes/:** `auth.py`, `act.py`, `ai_admin.py`, `banking.py`, `doctypes.py`, `estimates.py`, `maps.py`, `media.py`, `mobile.py`, `portal.py`, `proxy.py`, `public_api.py`, `scenarios.py`, `serial.py`, `signatures.py`, `sync.py`, `vault.py`, `visits.py`, `warehouse.py`
- **services/:** `admin_service.py`, `ai_orchestrator_service.py`, `ai_service.py`, `drive_service.py`, `media_service.py`, `scenario_service.py`, `sync_service.py`
- **schemas/:** `admin.py`, `ai.py`, `ai_admin.py`, `auth.py`, `estimate.py`, `maps_warehouse.py`, `media.py`, `scenario.py`, `serial.py`, `sync.py`, `vault.py`
- **auth/:** `dependencies.py`, `jwt.py`, `permissions.py`
- **core/:** `config.py`, `database.py`, `redis.py`

**Verified:** `database.py` exports `frappe_get`, `frappe_post`, `frappe_put`, `frappe_delete`, `frappe_login`, `frappe_guest_get`, `frappe_guest_post`, `close_client`, `FRAPPE_HOST`. `permissions.py` exports `Role`, `Permission`, `has_permission`, `get_permissions`, `ROLE_PERMISSIONS`.

---

## 2. Route Shadowing (main.py include_router order)

### Registration order (main.py lines 100-120):

```
Line 100: auth_router        (prefix=/api/v2/auth)
Line 101: banking_router     (prefix=/api/v1/banking)
Line 102: signatures_router  (prefix=/api/v1/signatures)
Line 103: portal_router      (prefix=/api/v1/portal)
Line 104: public_router      (prefix=/api/v1/public)
Line 105: mobile_router      (prefix=/api/v1/mobile)
Line 106: estimates_router   (prefix=/api/v2/estimates)    ← BEFORE doctypes ✅
Line 107: media_router       (prefix=/api/v2/media)        ← BEFORE doctypes ✅
Line 108: scenarios_router   (prefix=/api/v2/scenarios)    ← BEFORE doctypes ✅
Line 109: ai_admin_router    (prefix=/api/v2/ai-admin)     ← BEFORE doctypes ✅
Line 110: doctypes_router    (prefix=/api/v2)              ← CATCH-ALL ⚠️
Line 111: visits_router      (no prefix, self-defines /api/v1/visits/* and /api/v2/visits/*)
Line 112: vault_router       (prefix=/api/v2/vault)        ← AFTER doctypes
Line 113: act_router         (prefix=/api/v2/vault/act)    ← AFTER doctypes
Line 114: act_public_router  (prefix=/api/v2/act/public)   ← AFTER doctypes
Line 115: ai_router          (prefix=/api/v2/ai)           ← AFTER doctypes
Line 116: sync_router        (prefix=/api/v2/sync)         ← AFTER doctypes
Line 117: serial_router      (prefix=/api/v2/serial)       ← AFTER doctypes
Line 118: maps_router        (prefix=/api/v2/maps)         ← AFTER doctypes
Line 119: warehouse_router   (prefix=/api/v2/warehouse)    ← AFTER doctypes
Line 120: proxy_router       (catch-all /api/v1/{path})
```

### Shadowing analysis:

**Critical:** `doctypes_router` has `prefix="/api/v2"` and is registered at line 110. Any routes registered AFTER it that share the `/api/v2` prefix are at risk of being shadowed.

**Current status:** No functional shadowing exists because `doctypes.py` does NOT define routes that match the specific prefixes of later routers (`/vault/*`, `/ai/*`, `/sync/*`, `/serial/*`, `/maps/*`, `/warehouse/*`, `/act/*`). However, `doctypes.py` acts as a **catch-all for unmatched `/api/v2/*` paths** — any misspelled or future route under `/api/v2/` that doesn't match a more specific router will be handled by `doctypes.py` instead of returning 404.

**Risk:** If a new route file is added with a prefix that overlaps with an existing `doctypes.py` route, it will be silently shadowed.

---

## 3. Dead Code Files (never imported)

| File | Evidence |
|------|----------|
| `services/scenario_service.py` | Not imported by any file. `routes/scenarios.py` calls Frappe REST API directly. |
| `services/media_service.py` | Not imported by any file. `routes/media.py` has inline logic instead of delegating to service. |
| `services/admin_service.py` | Not imported by any file. `routes/ai_admin.py` has inline logic calling `frappe_get/post/put` directly. |
| `schemas/admin.py` | Not imported by any file. `routes/ai_admin.py` imports from `schemas/ai_admin.py` instead. Contains duplicate `AIProviderUpsertRequest` and unused `DegradationResponse`. |

**Note:** `services/ai_service.py` is imported by nothing in routes/ — but it defines `ai_service = AIService()` singleton. It may be used by other modules outside `services/security-api/` or is legacy code from before the orchestrator refactor. Verify before deleting.

---

## 4. Unused Imports

| File:Line | Unused Import | Notes |
|-----------|---------------|-------|
| `routes/visits.py:1` | `base64` | Used only in `upload_photo_v1` — actually used ✅ (false positive on initial scan, `base64.b64encode` at line 98) |
| `routes/visits.py:2` | `Request` | Imported but never used in function signatures or body |
| `routes/visits.py:4` | `Optional` | Used in `VisitMaterialRequest` model ✅ (false positive) |
| `routes/proxy.py:1` | `json` | Used in `_proxy` handler for error responses ✅ (false positive) |
| `routes/proxy.py:7` | `has_permission` | Imported from `app.auth.permissions` but never called |
| `routes/portal.py:3` | `uuid` | Imported but `uuid.uuid4()` is used in `portal_create_ticket` ✅ (false positive) |
| `routes/public_api.py:2` | `datetime`, `timezone` | Imported but never used in any handler |
| `routes/signatures.py:2` | `uuid` | Used in `create_signature_request` ✅ (false positive) |
| `routes/banking.py:2` | `uuid` | Imported but never used in any handler |
| `routes/warehouse.py:6` | `json` | Used for `json.dumps(filters)` ✅ (false positive) |
| `schemas/auth.py:3` | `UUID` | Used in `UserCreate.employee_id` ✅ (false positive) |
| `schemas/auth.py:4` | `datetime` | Used in `UserResponse.created_at` ✅ (false positive) |

### Confirmed unused imports:

| File:Line | Import | Reason |
|-----------|--------|--------|
| `routes/visits.py:2` | `Request` | Not referenced in any handler signature or body |
| `routes/proxy.py:7` | `has_permission` | Imported from `app.auth.permissions` but proxy uses `_has_access()` with role map instead |
| `routes/public_api.py:2` | `datetime, timezone` | Not referenced in any handler |
| `routes/banking.py:2` | `uuid` | Not referenced in any handler |

---

## 5. Route Conflicts Between doctypes.py and New Routers

### 5.1 Conflicting route patterns:

| doctypes.py route | Conflicting router | Conflict type |
|-------------------|-------------------|---------------|
| `POST /scenarios/{scenario_id}/apply` (line 202) | `scenarios.py` `POST /api/v2/scenarios` | Prefix overlap. `scenarios.py` registered first → `/api/v2/scenarios` correctly routes to `scenarios.py`. `doctypes.py` catches `/api/v2/scenarios/{id}/apply`. No functional conflict but confusing API surface. |
| `POST /scenarios/{scenario_name}/calculate` (line 604) | `scenarios.py` `GET /api/v2/scenarios/{name}` | Same prefix. `scenarios.py` GET wins for `GET /api/v2/scenarios/X`. `doctypes.py` catches `POST /api/v2/scenarios/X/calculate`. |
| `GET /quotations/{name}` (line 110) | `doctypes.py` `GET /quotations` (line 335) | Same file — `/quotations` list vs `/quotations/{name}` detail. FastAPI resolves correctly (more specific wins). |
| `/{path:path}` catch-all (implicit from prefix="/api/v2") | All routers registered after line 110 | `doctypes.py` catches any `/api/v2/*` path not matched by earlier routers. Not a functional bug but prevents proper 404 for invalid paths. |

### 5.2 R4 gateway discipline violations:

The following routes in `doctypes.py` call `frappe_get/post/put` directly, bypassing the service layer mandated by R4:

- `GET /settings` (line 89)
- `PUT /settings` (line 95)
- `GET /quotations/{name}` (line 110)
- `PUT /quotations/{name}` (line 119)
- `POST /contracts` (line 130)
- `POST /installation-acts` (line 146)
- `POST /warranty-cards` (line 172)
- `GET /purchase-orders/{name}/items` (line 193)
- `POST /scenarios/{scenario_id}/apply` (line 202)
- `POST /warranty/scan` (line 242)
- `GET /warranty/card/{card_id}` (line 265)
- `POST /quotation` (line 302)
- `GET /quotations` (line 335)
- `POST /quotation/{qt_name}/create-order` (line 355)
- `POST /quotation/{qt_name}/create-po` (line 383)
- `POST /purchase-order/{po_name}/create-invoice` (line 447)
- `POST /sales-invoice/{si_name}/create-act` (line 512)
- `GET /pricing/calculate` (line 534)
- `GET /pricing/margin` (line 570)
- `POST /scenarios/{scenario_name}/calculate` (line 604)

**Also violates R4:** `routes/scenarios.py` calls `frappe_get/post/put` directly (lines 43, 72, 106, 113, 132, 140, 162, 172).

### 5.3 Specific route conflict matrix:

| Path | doctypes.py | scenarios.py | estimates.py | ai.py | Result |
|------|-------------|-------------|-------------|-------|--------|
| `GET /api/v2/scenarios` | ❌ | ✅ `list_scenarios` | — | — | scenarios wins (registered first) |
| `GET /api/v2/scenarios/{name}` | ❌ | ✅ `get_scenario` | — | — | scenarios wins |
| `POST /api/v2/scenarios` | ❌ | ✅ `upsert_scenario` | — | — | scenarios wins |
| `POST /api/v2/scenarios/{id}/apply` | ✅ `apply_scenario` | ❌ | — | — | doctypes catches (no conflict) |
| `POST /api/v2/scenarios/{name}/calculate` | ✅ `calculate_scenario` | ❌ | — | — | doctypes catches (no conflict) |
| `POST /api/v2/scenarios/{name}/items` | ❌ | ✅ `upsert_scenario_item` | — | — | scenarios wins |
| `POST /api/v2/estimates/build` | ❌ | — | ✅ `estimate_build` | — | estimates wins |
| `POST /api/v2/estimates/{name}/review` | ❌ | — | ✅ `estimate_review` | — | estimates wins |
| `POST /api/v2/estimates/{name}/confirm` | ❌ | — | ✅ `estimate_confirm` | — | estimates wins |

**Conclusion:** No functional route conflicts exist in the current code. The main issues are:
1. `doctypes.py` as catch-all prevents proper 404s for unmatched `/api/v2/*` paths
2. `doctypes.py` contains ~20 routes that should be extracted into dedicated service+route modules per R4
3. `scenarios.py` duplicates some scenario logic that also exists in `doctypes.py` (`apply_scenario`, `calculate_scenario`)

---

## 6. Summary of All Findings

### Critical (blocks functionality):
1. **`routes/ai.py:40-43`** — 4 `security_erp.*` imports broken in security-api container. `POST /api/v2/ai/execute` will crash with `ModuleNotFoundError`.

### High (architecture violation):
2. **`services/estimate_service.py:57`** — circular import `from app.routes.ai import _build_orchestrator` (R4 violation: service imports from routes)
3. **`doctypes.py`** — 20+ routes call `frappe_*` directly, bypassing service layer (R4 violation)
4. **`routes/scenarios.py`** — calls `frappe_get/post/put` directly instead of through `scenario_service.py` (R4 violation)

### Medium (dead code / maintenance):
5. **`services/scenario_service.py`** — dead code, never imported
6. **`services/media_service.py`** — dead code, never imported
7. **`services/admin_service.py`** — dead code, never imported
8. **`schemas/admin.py`** — dead code, never imported (duplicates `schemas/ai_admin.py`)

### Low (unused imports / cleanup):
9. `routes/visits.py:2` — unused `Request`
10. `routes/proxy.py:7` — unused `has_permission`
11. `routes/public_api.py:2` — unused `datetime, timezone`
12. `routes/banking.py:2` — unused `uuid`

### Informational:
13. `doctypes.py` registered at main.py:110 with `prefix="/api/v2"` acts as catch-all for unmatched `/api/v2/*` paths
14. `doctypes.py` has `POST /scenarios/{id}/apply` and `POST /scenarios/{name}/calculate` — legacy scenario routes that coexist with new `scenarios.py` router
