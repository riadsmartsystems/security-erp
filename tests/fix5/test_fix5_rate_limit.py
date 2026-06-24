"""FIX-5: R4 rate limit enforcement + R2 Ukrainian role mapping tests.

Run:
  cd "/home/joker/RIAD CRM"
  python -m unittest tests.fix5.test_fix5_rate_limit -v
"""

import asyncio
import os
import sys
import unittest
from unittest.mock import AsyncMock, patch

_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)

os.environ.setdefault("SECRET_KEY", "ci-test-secret-key-min-32-chars-ok")
os.environ.setdefault("FRAPPE_URL", "http://localhost:8000")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379")


def _run(coro):
    return asyncio.get_event_loop().run_until_complete(coro)


# ---------------------------------------------------------------------------
# R2: Ukrainian role name mapping
# ---------------------------------------------------------------------------

class TestUkrainianRoleMapping(unittest.TestCase):
    """Frappe Ukrainian role names must map to correct RBAC slugs."""

    def setUp(self):
        from app.routes.auth import _map_frappe_role_from_names
        self._map = _map_frappe_role_from_names

    def test_technician_maps_to_engineer(self):
        """DoD: Frappe User з роллю "Технік" → role: engineer."""
        self.assertEqual(self._map(["Технік"]), "engineer")

    def test_director_maps_to_director(self):
        self.assertEqual(self._map(["Директор"]), "director")

    def test_accountant_maps_to_accountant(self):
        self.assertEqual(self._map(["Бухгалтер"]), "accountant")

    def test_warehouse_maps_to_warehouse(self):
        self.assertEqual(self._map(["Склад"]), "warehouse")

    def test_system_manager_takes_priority_over_technician(self):
        self.assertEqual(self._map(["Технік", "System Manager"]), "owner")

    def test_empty_roles_give_viewer(self):
        self.assertEqual(self._map([]), "viewer")

    def test_unknown_role_gives_viewer(self):
        self.assertEqual(self._map(["UnknownCustomRole"]), "viewer")


# ---------------------------------------------------------------------------
# R4: Rate limit enforcement — _enforce_rate_limit raises 429 when limited
# ---------------------------------------------------------------------------

class TestRateLimitEnforcement(unittest.TestCase):
    """DoD: 6th login attempt in 900s window → 429 Too Many Requests."""

    def test_sixth_attempt_raises_429(self):
        """When check_rate_limit returns limited=True, endpoint must return 429."""
        from fastapi import HTTPException
        from app.routes.auth import _enforce_rate_limit

        with patch("app.routes.auth.check_rate_limit", new_callable=AsyncMock) as mock_rl:
            # Simulate state after 5 previous attempts — 6th triggers limit
            mock_rl.return_value = {"limited": True, "retry_after": 850}
            with self.assertRaises(HTTPException) as ctx:
                _run(_enforce_rate_limit("rl:login:1.2.3.4", 5, 900))
            exc = ctx.exception
            self.assertEqual(exc.status_code, 429)
            self.assertEqual(exc.headers["Retry-After"], "850")

    def test_fifth_attempt_passes(self):
        """5th attempt (under limit) must not raise."""
        from app.routes.auth import _enforce_rate_limit

        with patch("app.routes.auth.check_rate_limit", new_callable=AsyncMock) as mock_rl:
            mock_rl.return_value = {"limited": False, "retry_after": None}
            _run(_enforce_rate_limit("rl:login:1.2.3.4", 5, 900))

    def test_rate_limit_called_with_correct_login_key_format(self):
        """Login key format: rl:login:{ip}."""
        from app.routes.auth import _enforce_rate_limit

        with patch("app.routes.auth.check_rate_limit", new_callable=AsyncMock) as mock_rl:
            mock_rl.return_value = {"limited": False, "retry_after": None}
            _run(_enforce_rate_limit("rl:login:192.168.1.1", 5, 900))
            called_key = mock_rl.call_args[0][0]
            self.assertIn("login", called_key)
            self.assertIn("192.168.1.1", called_key)

    def test_rate_limit_called_with_correct_refresh_key_format(self):
        """Refresh key format: rl:refresh:{user_id}."""
        from app.routes.auth import _enforce_rate_limit

        with patch("app.routes.auth.check_rate_limit", new_callable=AsyncMock) as mock_rl:
            mock_rl.return_value = {"limited": False, "retry_after": None}
            user_id = "technician@company.com"
            _run(_enforce_rate_limit(f"rl:refresh:{user_id}", 30, 900))
            called_key = mock_rl.call_args[0][0]
            self.assertIn("refresh", called_key)
            self.assertIn(user_id, called_key)

    def test_refresh_429_carries_retry_after_header(self):
        """Refresh rate limit 429 must include Retry-After header."""
        from fastapi import HTTPException
        from app.routes.auth import _enforce_rate_limit

        with patch("app.routes.auth.check_rate_limit", new_callable=AsyncMock) as mock_rl:
            mock_rl.return_value = {"limited": True, "retry_after": 600}
            with self.assertRaises(HTTPException) as ctx:
                _run(_enforce_rate_limit("rl:refresh:user@x.com", 30, 900))
            self.assertEqual(ctx.exception.status_code, 429)
            self.assertEqual(ctx.exception.headers["Retry-After"], "600")


# ---------------------------------------------------------------------------
# R4: check_rate_limit module — structural contract
# ---------------------------------------------------------------------------

class TestRateLimitModule(unittest.TestCase):
    """check_rate_limit must return the correct dict shape."""

    def test_returns_dict_with_limited_key(self):
        """check_rate_limit always returns {'limited': bool, 'retry_after': int|None}."""
        from unittest.mock import MagicMock
        from app.core.rate_limit import check_rate_limit

        # Pipeline commands are sync (queued), only execute() is async
        mock_pipe = MagicMock()
        mock_pipe.zremrangebyscore = MagicMock()
        mock_pipe.zadd = MagicMock()
        mock_pipe.zcard = MagicMock()
        mock_pipe.expire = MagicMock()
        # count=3 → under limit of 5 → not limited
        mock_pipe.execute = AsyncMock(return_value=[0, 1, 3, True])

        mock_redis = MagicMock()
        mock_redis.pipeline = MagicMock(return_value=mock_pipe)

        with patch("app.core.rate_limit.get_redis", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_redis
            result = _run(check_rate_limit("test:key", 5, 900))

        self.assertIn("limited", result)
        self.assertIn("retry_after", result)
        self.assertIsInstance(result["limited"], bool)

    def test_returns_limited_true_when_count_exceeds_max(self):
        """count > max_attempts → limited: True."""
        from unittest.mock import MagicMock
        from app.core.rate_limit import check_rate_limit

        mock_pipe = MagicMock()
        mock_pipe.zremrangebyscore = MagicMock()
        mock_pipe.zadd = MagicMock()
        mock_pipe.zcard = MagicMock()
        mock_pipe.expire = MagicMock()
        # count=6 > max=5 → limited
        mock_pipe.execute = AsyncMock(return_value=[0, 1, 6, True])

        mock_redis = MagicMock()
        mock_redis.pipeline = MagicMock(return_value=mock_pipe)
        mock_redis.zrange = AsyncMock(return_value=[(b"entry", 1750000000.0)])

        with patch("app.core.rate_limit.get_redis", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_redis
            result = _run(check_rate_limit("test:key", 5, 900))

        self.assertTrue(result["limited"])
        self.assertIsNotNone(result["retry_after"])
        self.assertGreater(result["retry_after"], 0)


if __name__ == "__main__":
    unittest.main()
