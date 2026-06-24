"""Unit tests for scripts/check_gateway_discipline.py.

TDD: RED → script not found → implement script → GREEN.

Run:
  cd "/home/joker/RIAD CRM"
  python -m unittest tests.fix6.test_check_gateway_discipline -v
"""
import os
import pathlib
import shutil
import sys
import tempfile
import unittest

# ---------------------------------------------------------------------------
# Dynamic import of the script (it lives in scripts/, not a package)
# ---------------------------------------------------------------------------
_scripts_root = os.path.join(os.path.dirname(__file__), "..", "..", "scripts")
_script_path = os.path.join(_scripts_root, "check_gateway_discipline.py")

try:
    import importlib.util

    if not os.path.exists(_script_path):
        raise FileNotFoundError(f"Script not found: {_script_path}")
    _spec = importlib.util.spec_from_file_location("check_gateway_discipline", _script_path)
    _mod = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(_mod)
    check_file = _mod.check_file
    scan_routes = _mod.scan_routes
    main = _mod.main
    _import_error = None
except Exception as exc:
    check_file = None
    scan_routes = None
    main = None
    _import_error = str(exc)


def _require_module(tc):
    if check_file is None:
        tc.fail(
            f"check_gateway_discipline.py not found or broken — "
            f"implement scripts/check_gateway_discipline.py first. "
            f"Error: {_import_error}"
        )


# =============================================================================
# check_file — EXCLUDED files
# =============================================================================


class TestCheckFileExcluded(unittest.TestCase):
    """Excluded files return EXCLUDED regardless of frappe_* content."""

    def setUp(self):
        _require_module(self)

    def test_act_py_excluded(self):
        status, _ = check_file("act.py", "await frappe_post('/api/method/vault.act')")
        self.assertEqual(status, "EXCLUDED")

    def test_vault_py_excluded(self):
        status, _ = check_file("vault.py", "await frappe_get('/api/resource/X')")
        self.assertEqual(status, "EXCLUDED")

    def test_auth_py_excluded(self):
        status, _ = check_file("auth.py", "await frappe_post('/login')")
        self.assertEqual(status, "EXCLUDED")

    def test_proxy_py_excluded(self):
        status, _ = check_file("proxy.py", "cookies = {'sid': sid}")
        self.assertEqual(status, "EXCLUDED")

    def test_doctypes_py_excluded(self):
        status, _ = check_file("doctypes.py", "await frappe_get('/api/resource/Settings')")
        self.assertEqual(status, "EXCLUDED")


# =============================================================================
# check_file — KNOWN_PENDING files (TODO, do not fail CI)
# =============================================================================


class TestCheckFileKnownPending(unittest.TestCase):
    """Known-pending files report TODO but do NOT fail CI."""

    def setUp(self):
        _require_module(self)

    def test_serial_py_is_todo(self):
        content = (
            "from app.core.database import frappe_post\n"
            "result = await frappe_post('/api/method/security_erp.serial_scan.record_serial_scan', data=data, sid=sid)\n"
        )
        status, _ = check_file("serial.py", content)
        self.assertEqual(status, "TODO")

    def test_scenarios_py_is_todo(self):
        content = "from app.core.database import frappe_get, frappe_post, frappe_put\n"
        status, _ = check_file("scenarios.py", content)
        self.assertEqual(status, "TODO")

    def test_serial_py_todo_reason_mentions_pending(self):
        _, reason = check_file("serial.py", "await frappe_post('/something')")
        self.assertIn("pending", reason.lower())


# =============================================================================
# check_file — OK files (no frappe_* calls)
# =============================================================================


class TestCheckFileOK(unittest.TestCase):
    """Files with no direct frappe_* calls return OK."""

    def setUp(self):
        _require_module(self)

    def test_clean_route_file_is_ok(self):
        content = (
            "from app.services import visit_service\n\n"
            "async def get_visits(current_user):\n"
            "    return await visit_service.list_all(sid=current_user.frappe_sid)\n"
        )
        status, _ = check_file("visits.py", content)
        self.assertEqual(status, "OK")

    def test_file_delegating_to_service_is_ok(self):
        content = "from app.services import warehouse_service\n"
        status, _ = check_file("warehouse.py", content)
        self.assertEqual(status, "OK")

    def test_empty_file_is_ok(self):
        status, _ = check_file("some_route.py", "")
        self.assertEqual(status, "OK")

    def test_file_with_frappe_in_comment_substring_ok(self):
        # "frappe_service" does not match "frappe_get" — no false positive
        content = "# Delegates all frappe_service calls to service layer\n"
        # Actually this DOES contain "frappe_" prefix - depends on implementation
        # The key is that exact tokens frappe_get/post/put must not be present
        content = "# see frappe documentation — use service layer\n"
        status, _ = check_file("visits.py", content)
        self.assertEqual(status, "OK")


# =============================================================================
# check_file — VIOLATION (unexpected frappe_* in non-excluded, non-pending file)
# =============================================================================


class TestCheckFileViolation(unittest.TestCase):
    """Unexpected frappe_* calls in any non-excluded, non-pending file → VIOLATION."""

    def setUp(self):
        _require_module(self)

    def test_new_file_with_frappe_get_is_violation(self):
        content = "result = await frappe_get('/api/resource/Something', sid=sid)"
        status, reason = check_file("new_feature.py", content)
        self.assertEqual(status, "VIOLATION")
        self.assertIn("frappe_get", reason)

    def test_new_file_with_frappe_post_is_violation(self):
        content = "result = await frappe_post('/api/resource/Something', data={}, sid=sid)"
        status, _ = check_file("new_feature.py", content)
        self.assertEqual(status, "VIOLATION")

    def test_new_file_with_frappe_put_is_violation(self):
        content = "result = await frappe_put('/api/resource/Item/1', data={}, sid=sid)"
        status, _ = check_file("refactored_oops.py", content)
        self.assertEqual(status, "VIOLATION")

    def test_violation_reason_contains_forbidden_function_name(self):
        content = "await frappe_get('/api/resource/X')\nawait frappe_put('/api/resource/Y')"
        status, reason = check_file("bad.py", content)
        self.assertEqual(status, "VIOLATION")
        # reason should name at least one forbidden function
        self.assertTrue(
            any(fn in reason for fn in ("frappe_get", "frappe_post", "frappe_put")),
            f"Reason should name the forbidden call, got: {reason}",
        )


# =============================================================================
# check_file — ai.py special case
# =============================================================================


class TestCheckFileAISpecial(unittest.TestCase):
    """ai.py: frappe_post to whitelist is OK; frappe_get/put/delete = VIOLATION."""

    def setUp(self):
        _require_module(self)

    def test_ai_py_with_only_frappe_post_is_ok(self):
        content = (
            "from app.core.database import frappe_post\n"
            "result = await frappe_post(\n"
            "    '/api/method/security_erp.ai.api.execute_ai',\n"
            "    data={'task': task, 'payload': payload},\n"
            ")\n"
        )
        status, _ = check_file("ai.py", content)
        self.assertEqual(status, "OK")

    def test_ai_py_with_frappe_get_is_violation(self):
        content = (
            "from app.core.database import frappe_get, frappe_post\n"
            "providers = await frappe_get('/api/resource/AI Provider', sid=sid)\n"
        )
        status, reason = check_file("ai.py", content)
        self.assertEqual(status, "VIOLATION")
        self.assertIn("frappe_get", reason)

    def test_ai_py_with_frappe_put_is_violation(self):
        content = (
            "from app.core.database import frappe_post, frappe_put\n"
            "await frappe_put('/api/resource/AI Provider/1', data={}, sid=sid)\n"
        )
        status, _ = check_file("ai.py", content)
        self.assertEqual(status, "VIOLATION")

    def test_ai_py_clean_no_frappe_calls_is_ok(self):
        content = "from app.services import ai_orchestrator_service\n"
        status, _ = check_file("ai.py", content)
        self.assertEqual(status, "OK")


# =============================================================================
# scan_routes — filesystem scan
# =============================================================================


class TestScanRoutes(unittest.TestCase):
    """scan_routes classifies all .py files in a directory."""

    def setUp(self):
        _require_module(self)
        self.tmpdir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tmpdir, ignore_errors=True)

    def _write(self, filename, content=""):
        pathlib.Path(self.tmpdir, filename).write_text(content, encoding="utf-8")
        return filename

    def test_scan_empty_directory_returns_empty(self):
        results = scan_routes(self.tmpdir)
        self.assertEqual(results, [])

    def test_scan_classifies_clean_file_as_ok(self):
        self._write("visits.py", "from app.services import visit_service\n")
        results = scan_routes(self.tmpdir)
        statuses = {r[0]: r[1] for r in results}
        self.assertEqual(statuses.get("visits.py"), "OK")

    def test_scan_classifies_serial_py_as_todo(self):
        self._write("serial.py", "await frappe_post('/api/method/x', data={}, sid=sid)\n")
        results = scan_routes(self.tmpdir)
        statuses = {r[0]: r[1] for r in results}
        self.assertEqual(statuses.get("serial.py"), "TODO")

    def test_scan_classifies_scenarios_py_as_todo(self):
        self._write("scenarios.py", "await frappe_get('/api/resource/Scenario')\n")
        results = scan_routes(self.tmpdir)
        statuses = {r[0]: r[1] for r in results}
        self.assertEqual(statuses.get("scenarios.py"), "TODO")

    def test_scan_classifies_act_py_as_excluded(self):
        self._write("act.py", "await frappe_post('/api/method/vault.act')\n")
        results = scan_routes(self.tmpdir)
        statuses = {r[0]: r[1] for r in results}
        self.assertEqual(statuses.get("act.py"), "EXCLUDED")

    def test_scan_detects_violation_in_new_file(self):
        self._write("new_feature.py", "await frappe_get('/api/resource/Something')\n")
        results = scan_routes(self.tmpdir)
        statuses = {r[0]: r[1] for r in results}
        self.assertEqual(statuses.get("new_feature.py"), "VIOLATION")

    def test_scan_skips_init_py(self):
        self._write("__init__.py", "")
        self._write("visits.py", "")
        results = scan_routes(self.tmpdir)
        filenames = [r[0] for r in results]
        self.assertNotIn("__init__.py", filenames)
        self.assertIn("visits.py", filenames)

    def test_scan_returns_three_tuple_per_file(self):
        self._write("visits.py", "")
        results = scan_routes(self.tmpdir)
        self.assertEqual(len(results[0]), 3)
        filename, status, reason = results[0]
        self.assertEqual(filename, "visits.py")
        self.assertIsInstance(status, str)
        self.assertIsInstance(reason, str)


# =============================================================================
# main() — exit codes
# =============================================================================


class TestMainExitCode(unittest.TestCase):
    """main() returns 0 (no violations) or 1 (unexpected violation found)."""

    def setUp(self):
        _require_module(self)
        self.tmpdir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tmpdir, ignore_errors=True)

    def _write(self, filename, content=""):
        pathlib.Path(self.tmpdir, filename).write_text(content, encoding="utf-8")

    def test_exit_0_when_only_known_pending_violations(self):
        """serial.py and scenarios.py (KNOWN_PENDING) must not fail CI."""
        self._write("serial.py", "await frappe_post('/api/resource/Serial No', data={}, sid=sid)\n")
        self._write("scenarios.py", "await frappe_get('/api/resource/Scenario')\n")
        self._write("visits.py", "from app.services import visit_service\n")
        code = main(self.tmpdir)
        self.assertEqual(code, 0)

    def test_exit_1_when_unexpected_violation_in_new_file(self):
        """A new file with frappe_* calls triggers regression guard."""
        self._write("new_feature.py", "await frappe_get('/api/resource/Something')\n")
        code = main(self.tmpdir)
        self.assertEqual(code, 1)

    def test_exit_0_when_all_files_clean(self):
        self._write("visits.py", "from app.services import visit_service\n")
        self._write("warehouse.py", "from app.services import warehouse_service\n")
        code = main(self.tmpdir)
        self.assertEqual(code, 0)

    def test_exit_0_with_excluded_files_containing_frappe(self):
        """Excluded files with frappe_* do not trigger the guard."""
        self._write("auth.py", "await frappe_get('/api/resource/User')\n")
        self._write("vault.py", "await frappe_post('/api/method/vault.something')\n")
        code = main(self.tmpdir)
        self.assertEqual(code, 0)

    def test_exit_0_with_ai_py_having_only_frappe_post(self):
        """ai.py with frappe_post (whitelist pattern) does not trigger the guard."""
        self._write(
            "ai.py",
            "from app.core.database import frappe_post\n"
            "await frappe_post('/api/method/security_erp.ai.api.execute_ai', data={})\n",
        )
        code = main(self.tmpdir)
        self.assertEqual(code, 0)

    def test_exit_1_when_ai_py_has_frappe_get(self):
        """ai.py with frappe_get violates discipline (not the allowed whitelist pattern)."""
        self._write("ai.py", "await frappe_get('/api/resource/AI Provider')\n")
        code = main(self.tmpdir)
        self.assertEqual(code, 1)

    def test_exit_0_empty_directory(self):
        """Empty routes dir (no route files) → no violations → exit 0."""
        code = main(self.tmpdir)
        self.assertEqual(code, 0)


if __name__ == "__main__":
    unittest.main()
