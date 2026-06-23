"""C1 Calculator backend tests.

Run:
  cd "/home/joker/RIAD CRM"
  python3 -m pytest tests/c1/ -v
"""

import os
import sys
import unittest
from unittest.mock import AsyncMock, MagicMock, patch

_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)

os.environ.setdefault("SECRET_KEY", "ci-test-secret-key-min-32-chars-ok")
os.environ.setdefault("FRAPPE_URL", "http://localhost:8000")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379")


class TestCalculatorRateLimit(unittest.TestCase):
    """Rate limit: 6th request from same IP → 429."""

    @patch("app.routes.calculator.check_rate_limit", new_callable=AsyncMock)
    def test_sixth_request_returns_429(self, mock_rl):
        from fastapi import FastAPI
        from fastapi.testclient import TestClient
        from app.routes.calculator import router

        app = FastAPI()
        app.include_router(router)

        mock_rl.return_value = {"limited": True, "retry_after": 3500}

        client = TestClient(app)
        resp = client.post(
            "/api/v2/calculator/submit",
            json={
                "object_type": "CCTV IP",
                "area_m2": 100,
                "cameras_count": 4,
                "archive_days": 30,
                "contact_name": "Test",
                "contact_phone": "+380501234567",
                "captcha_token": "dummy",
            },
        )
        self.assertEqual(resp.status_code, 429)
        self.assertIn("Retry-After", resp.headers)
        self.assertEqual(resp.json()["detail"]["code"], "RATE_LIMIT_EXCEEDED")


class TestCalculatorCaptcha(unittest.TestCase):
    """CAPTCHA failure → 422."""

    @patch("app.routes.calculator.check_rate_limit", new_callable=AsyncMock)
    @patch("app.routes.calculator.verify_turnstile", new_callable=AsyncMock)
    def test_captcha_fail_returns_422(self, mock_captcha, mock_rl):
        from fastapi import FastAPI
        from fastapi.testclient import TestClient
        from app.routes.calculator import router

        app = FastAPI()
        app.include_router(router)

        mock_rl.return_value = {"limited": False, "retry_after": None}
        mock_captcha.return_value = False

        client = TestClient(app)
        resp = client.post(
            "/api/v2/calculator/submit",
            json={
                "object_type": "CCTV IP",
                "area_m2": 100,
                "cameras_count": 4,
                "archive_days": 30,
                "contact_name": "Test",
                "contact_phone": "+380501234567",
                "captcha_token": "bad-token",
            },
        )
        self.assertEqual(resp.status_code, 422)
        self.assertEqual(resp.json()["detail"]["code"], "CAPTCHA_FAILED")


class TestCalculatorScenarioMatch(unittest.TestCase):
    """Scenario match → estimated_total > 0, matched_scenario present."""

    @patch("app.routes.calculator.frappe_guest_post", new_callable=AsyncMock)
    @patch("app.routes.calculator.check_rate_limit", new_callable=AsyncMock)
    @patch("app.routes.calculator.verify_turnstile", new_callable=AsyncMock)
    def test_scenario_match_returns_total(self, mock_captcha, mock_rl, mock_frappe):
        from fastapi import FastAPI
        from fastapi.testclient import TestClient
        from app.routes.calculator import router

        app = FastAPI()
        app.include_router(router)

        mock_rl.return_value = {"limited": False, "retry_after": None}
        mock_captcha.return_value = True
        mock_frappe.return_value = {
            "message": {
                "name": "CALC-00001",
                "estimated_total": 15000.0,
                "matched_scenario": "Security Scenario-001",
                "status": "новий",
            }
        }

        client = TestClient(app)
        resp = client.post(
            "/api/v2/calculator/submit",
            json={
                "object_type": "CCTV IP",
                "area_m2": 200,
                "cameras_count": 8,
                "archive_days": 30,
                "contact_name": "Іван Петренко",
                "contact_phone": "+380501234567",
                "contact_email": "ivan@test.com",
                "captcha_token": "good-token",
            },
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertGreater(data["estimated_total"], 0)
        self.assertIsNotNone(data["matched_scenario"])
        self.assertEqual(data["status"], "новий")


class TestCalculatorScenarioMiss(unittest.TestCase):
    """Scenario miss → estimated_total=0, status=новий."""

    @patch("app.routes.calculator.frappe_guest_post", new_callable=AsyncMock)
    @patch("app.routes.calculator.check_rate_limit", new_callable=AsyncMock)
    @patch("app.routes.calculator.verify_turnstile", new_callable=AsyncMock)
    def test_scenario_miss_returns_zero(self, mock_captcha, mock_rl, mock_frappe):
        from fastapi import FastAPI
        from fastapi.testclient import TestClient
        from app.routes.calculator import router

        app = FastAPI()
        app.include_router(router)

        mock_rl.return_value = {"limited": False, "retry_after": None}
        mock_captcha.return_value = True
        mock_frappe.return_value = {
            "message": {
                "name": "CALC-00002",
                "estimated_total": 0,
                "matched_scenario": None,
                "status": "новий",
            }
        }

        client = TestClient(app)
        resp = client.post(
            "/api/v2/calculator/submit",
            json={
                "object_type": "Unknown Type",
                "area_m2": 50,
                "cameras_count": 2,
                "archive_days": 7,
                "contact_name": "Тест",
                "contact_phone": "+380501234568",
                "captcha_token": "good-token",
            },
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["estimated_total"], 0)
        self.assertEqual(data["status"], "новий")
        self.assertIsNone(data["matched_scenario"])


class TestCalculatorPIIIsolation(unittest.TestCase):
    """PII fields not exposed in API response."""

    @patch("app.routes.calculator.frappe_guest_post", new_callable=AsyncMock)
    @patch("app.routes.calculator.check_rate_limit", new_callable=AsyncMock)
    @patch("app.routes.calculator.verify_turnstile", new_callable=AsyncMock)
    def test_contact_phone_not_in_response(self, mock_captcha, mock_rl, mock_frappe):
        from fastapi import FastAPI
        from fastapi.testclient import TestClient
        from app.routes.calculator import router

        app = FastAPI()
        app.include_router(router)

        mock_rl.return_value = {"limited": False, "retry_after": None}
        mock_captcha.return_value = True
        mock_frappe.return_value = {
            "message": {
                "name": "CALC-00003",
                "estimated_total": 5000.0,
                "matched_scenario": "Security Scenario-002",
                "status": "новий",
            }
        }

        client = TestClient(app)
        resp = client.post(
            "/api/v2/calculator/submit",
            json={
                "object_type": "Alarm",
                "area_m2": 100,
                "cameras_count": 0,
                "archive_days": 14,
                "contact_name": "Secret Person",
                "contact_phone": "+380509999999",
                "contact_email": "secret@test.com",
                "captcha_token": "good-token",
            },
        )
        self.assertEqual(resp.status_code, 200)
        resp_body = resp.text
        self.assertNotIn("+380509999999", resp_body)
        self.assertNotIn("Secret Person", resp_body)
        self.assertNotIn("secret@test.com", resp_body)


class TestCalculatorSubmitSavesSubmission(unittest.TestCase):
    """Submission is saved to Frappe on success."""

    @patch("app.routes.calculator.frappe_guest_post", new_callable=AsyncMock)
    @patch("app.routes.calculator.check_rate_limit", new_callable=AsyncMock)
    @patch("app.routes.calculator.verify_turnstile", new_callable=AsyncMock)
    def test_frappe_called_with_correct_data(self, mock_captcha, mock_rl, mock_frappe):
        from fastapi import FastAPI
        from fastapi.testclient import TestClient
        from app.routes.calculator import router

        app = FastAPI()
        app.include_router(router)

        mock_rl.return_value = {"limited": False, "retry_after": None}
        mock_captcha.return_value = True
        mock_frappe.return_value = {
            "message": {
                "name": "CALC-00004",
                "estimated_total": 0,
                "matched_scenario": None,
                "status": "новий",
            }
        }

        client = TestClient(app)
        client.post(
            "/api/v2/calculator/submit",
            json={
                "object_type": "Access Control",
                "area_m2": 300,
                "cameras_count": 0,
                "archive_days": 90,
                "contact_name": "Олена",
                "contact_phone": "+380671111111",
                "captcha_token": "tok",
            },
        )

        mock_frappe.assert_called_once()
        call_args = mock_frappe.call_args
        self.assertEqual(call_args[0][0], "/api/method/security_erp.calculator.submit")
        payload = call_args[1]["data"]
        self.assertEqual(payload["object_type"], "Access Control")
        self.assertEqual(payload["area_m2"], 300)
        self.assertEqual(payload["contact_phone"], "+380671111111")
        self.assertEqual(payload["source_ip"], "testclient")


class TestCalculatorInputValidation(unittest.TestCase):
    """Invalid input → 422 (Pydantic validation)."""

    def test_missing_required_field(self):
        from fastapi import FastAPI
        from fastapi.testclient import TestClient
        from app.routes.calculator import router

        app = FastAPI()
        app.include_router(router)

        client = TestClient(app)
        resp = client.post(
            "/api/v2/calculator/submit",
            json={"object_type": "CCTV IP"},
        )
        self.assertEqual(resp.status_code, 422)

    def test_negative_area_rejected(self):
        from fastapi import FastAPI
        from fastapi.testclient import TestClient
        from app.routes.calculator import router

        app = FastAPI()
        app.include_router(router)

        client = TestClient(app)
        resp = client.post(
            "/api/v2/calculator/submit",
            json={
                "object_type": "CCTV IP",
                "area_m2": -10,
                "cameras_count": 4,
                "archive_days": 30,
                "contact_name": "Test",
                "contact_phone": "+380501234567",
                "captcha_token": "tok",
            },
        )
        self.assertEqual(resp.status_code, 422)


class TestCalculatorFrappeError(unittest.TestCase):
    """Frappe backend error → 502."""

    @patch("app.routes.calculator.frappe_guest_post", new_callable=AsyncMock)
    @patch("app.routes.calculator.check_rate_limit", new_callable=AsyncMock)
    @patch("app.routes.calculator.verify_turnstile", new_callable=AsyncMock)
    def test_frappe_error_returns_502(self, mock_captcha, mock_rl, mock_frappe):
        from fastapi import FastAPI
        from fastapi.testclient import TestClient
        from app.routes.calculator import router

        app = FastAPI()
        app.include_router(router)

        mock_rl.return_value = {"limited": False, "retry_after": None}
        mock_captcha.return_value = True
        mock_frappe.side_effect = Exception("Connection refused")

        client = TestClient(app)
        resp = client.post(
            "/api/v2/calculator/submit",
            json={
                "object_type": "CCTV IP",
                "area_m2": 100,
                "cameras_count": 4,
                "archive_days": 30,
                "contact_name": "Test",
                "contact_phone": "+380501234567",
                "captcha_token": "tok",
            },
        )
        self.assertEqual(resp.status_code, 502)
        self.assertEqual(resp.json()["detail"]["code"], "FRAPPE_ERROR")


class TestCalculatorRetryAfterValue(unittest.TestCase):
    """Retry-After header contains a positive integer."""

    @patch("app.routes.calculator.check_rate_limit", new_callable=AsyncMock)
    def test_retry_after_is_positive_integer(self, mock_rl):
        from fastapi import FastAPI
        from fastapi.testclient import TestClient
        from app.routes.calculator import router

        app = FastAPI()
        app.include_router(router)

        mock_rl.return_value = {"limited": True, "retry_after": 3500}

        client = TestClient(app)
        resp = client.post(
            "/api/v2/calculator/submit",
            json={
                "object_type": "CCTV IP",
                "area_m2": 100,
                "cameras_count": 4,
                "archive_days": 30,
                "contact_name": "Test",
                "contact_phone": "+380501234567",
                "captcha_token": "dummy",
            },
        )
        self.assertEqual(resp.status_code, 429)
        retry_after = int(resp.headers["Retry-After"])
        self.assertGreater(retry_after, 0)
