"""FIX-4 tests: A3/A4 AI task bugs (RED → GREEN verification).

Bug A: enqueue_ai_estimate missing in tasks/ai_estimate.py
Bug B: is_active filter → must be is_enabled (field doesn't exist in AI Provider DocType)
Bug C: transcription_status options must include 'failed' (not 'manual'), cover transcribe.py values

Run:
  PYTHONPATH=erpnext/security_erp python3 -m pytest tests/fix4/ -v
"""

import importlib
import inspect
import json
import os
import sys
import unittest
from unittest.mock import MagicMock

# Paths
_erpnext_root = os.path.join(os.path.dirname(__file__), "..", "..", "erpnext", "security_erp")
if os.path.isdir(_erpnext_root):
    sys.path.insert(0, _erpnext_root)

# redis is NOT mocked here — it's installed in test env and must remain a real
# package so that other test suites (r3, fix5) can do `import redis.asyncio`.
# ai_estimate._get_redis_sync() uses a lazy import and is never reached in
# these tests (frappe.get_all returns [] → no providers → no redis call).
# frappe/frappe.utils mocks are now per-class (setUp/tearDown) to avoid
# permanently poisoning sys.modules for other test suites.

_AI_DEPS = [
    "security_erp.ai",
    "security_erp.ai.adapters",
    "security_erp.ai.adapters.base",
    "security_erp.ai.adapters.gemini",
    "security_erp.ai.adapters.stub",
    "security_erp.ai.circuit_breaker",
]

_MEDIA_ASSET_JSON = os.path.join(
    os.path.dirname(__file__), "..", "..",
    "erpnext", "security_erp", "security_erp", "security_erp",
    "doctype", "media_asset", "media_asset.json",
)


def _fresh_import_ai_estimate():
    """Import ai_estimate with all heavy deps mocked (redis, adapters).

    frappe.whitelist() is patched to be an identity decorator so that
    decorated functions retain their real signatures and callable bodies.
    """
    for mod_name in _AI_DEPS:
        sys.modules[mod_name] = MagicMock()
    # Make @frappe.whitelist() pass through the real function (identity decorator)
    sys.modules["frappe"].whitelist.return_value = lambda f: f
    # Force re-import to pick up code changes
    if "security_erp.tasks.ai_estimate" in sys.modules:
        del sys.modules["security_erp.tasks.ai_estimate"]
    import security_erp.tasks.ai_estimate
    return security_erp.tasks.ai_estimate


# ---------------------------------------------------------------------------
# Bug A: enqueue_ai_estimate must exist and be a Frappe-whitelist entrypoint
# ---------------------------------------------------------------------------

class TestBugA_EnqueueAiEstimate(unittest.TestCase):

    def setUp(self):
        self._patcher = unittest.mock.patch.dict(sys.modules, {
            "frappe": MagicMock(),
            "frappe.utils": MagicMock(),
        })
        self._patcher.start()

    def tearDown(self):
        self._patcher.stop()

    def test_enqueue_ai_estimate_exists(self):
        """FAILS before fix: function doesn't exist."""
        mod = _fresh_import_ai_estimate()
        self.assertTrue(
            hasattr(mod, "enqueue_ai_estimate"),
            "enqueue_ai_estimate not found in tasks/ai_estimate.py — Bug A unresolved"
        )

    def test_enqueue_ai_estimate_is_callable(self):
        mod = _fresh_import_ai_estimate()
        self.assertTrue(callable(getattr(mod, "enqueue_ai_estimate", None)))

    def test_enqueue_ai_estimate_signature(self):
        """Must accept (estimate_name, site_brief, variant='standard')."""
        mod = _fresh_import_ai_estimate()
        fn = getattr(mod, "enqueue_ai_estimate", None)
        self.assertIsNotNone(fn)
        sig = inspect.signature(fn)
        params = list(sig.parameters.keys())
        self.assertIn("estimate_name", params, "estimate_name param missing")
        self.assertIn("site_brief", params, "site_brief param missing")
        self.assertIn("variant", params, "variant param missing")

    def test_enqueue_ai_estimate_calls_frappe_enqueue(self):
        """Must delegate to frappe.enqueue with run_ai_estimate path."""
        mod = _fresh_import_ai_estimate()
        mod.frappe.enqueue.reset_mock()
        mod.enqueue_ai_estimate("EST-001", "brief text", "standard")
        mod.frappe.enqueue.assert_called_once()
        call_args = mod.frappe.enqueue.call_args
        # First positional arg is the task dotted path
        task_path = call_args[0][0] if call_args[0] else ""
        self.assertIn("run_ai_estimate", task_path,
                      "frappe.enqueue must reference run_ai_estimate")

    def test_enqueue_ai_estimate_passes_estimate_name(self):
        """estimate_name must be forwarded to the RQ job."""
        mod = _fresh_import_ai_estimate()
        mod.frappe.enqueue.reset_mock()
        mod.enqueue_ai_estimate("EST-XYZ", "some brief", "optimal")
        call_kwargs = mod.frappe.enqueue.call_args[1]
        self.assertIn("estimate_name", call_kwargs,
                      "estimate_name not forwarded to frappe.enqueue kwargs")
        self.assertEqual(call_kwargs["estimate_name"], "EST-XYZ")


# ---------------------------------------------------------------------------
# Bug B: _get_providers_sync must filter by is_enabled, not is_active
# ---------------------------------------------------------------------------

class TestBugB_IsEnabledFilter(unittest.TestCase):

    def setUp(self):
        self._patcher = unittest.mock.patch.dict(sys.modules, {
            "frappe": MagicMock(),
            "frappe.utils": MagicMock(),
        })
        self._patcher.start()

    def tearDown(self):
        self._patcher.stop()

    def test_providers_filter_uses_is_enabled(self):
        """FAILS before fix: source has is_active."""
        mod = _fresh_import_ai_estimate()
        src = inspect.getsource(mod._get_providers_sync)
        self.assertIn("is_enabled", src,
                      "_get_providers_sync must use 'is_enabled' filter (AI Provider field name)")

    def test_providers_filter_not_is_active(self):
        """is_active does not exist in AI Provider DocType — must not be used."""
        mod = _fresh_import_ai_estimate()
        src = inspect.getsource(mod._get_providers_sync)
        self.assertNotIn("is_active", src,
                         "_get_providers_sync still uses 'is_active' which doesn't exist in DocType")

    def test_providers_query_returns_enabled_only(self):
        """frappe.get_all must be called with is_enabled=1 filter."""
        mod = _fresh_import_ai_estimate()
        mod.frappe.get_all.reset_mock()
        mod.frappe.get_all.return_value = []
        mod._get_providers_sync()
        mod.frappe.get_all.assert_called_once()
        call_kwargs = mod.frappe.get_all.call_args[1]
        filters = call_kwargs.get("filters", {})
        self.assertIn("is_enabled", filters,
                      "frappe.get_all must filter by is_enabled")
        self.assertEqual(filters["is_enabled"], 1)


# ---------------------------------------------------------------------------
# Bug C: transcription_status schema must match values used by transcribe.py
# ---------------------------------------------------------------------------

class TestBugC_TranscriptionStatusSchema(unittest.TestCase):

    def _load_schema(self):
        with open(_MEDIA_ASSET_JSON) as f:
            return json.load(f)

    def test_transcription_status_field_exists(self):
        schema = self._load_schema()
        fieldnames = [f["fieldname"] for f in schema["fields"]]
        self.assertIn("transcription_status", fieldnames,
                      "transcription_status missing from media_asset.json")

    def test_transcription_status_is_select(self):
        schema = self._load_schema()
        fields = {f["fieldname"]: f for f in schema["fields"]}
        self.assertEqual(fields["transcription_status"]["fieldtype"], "Select")

    def test_transcription_status_options_include_pending(self):
        schema = self._load_schema()
        fields = {f["fieldname"]: f for f in schema["fields"]}
        options = fields["transcription_status"]["options"].split("\n")
        self.assertIn("pending", options)

    def test_transcription_status_options_include_done(self):
        schema = self._load_schema()
        fields = {f["fieldname"]: f for f in schema["fields"]}
        options = fields["transcription_status"]["options"].split("\n")
        self.assertIn("done", options)

    def test_transcription_status_options_include_failed(self):
        """FAILS before fix: current options have 'manual' not 'failed'."""
        schema = self._load_schema()
        fields = {f["fieldname"]: f for f in schema["fields"]}
        options = fields["transcription_status"]["options"].split("\n")
        self.assertIn("failed", options,
                      "transcription_status must have 'failed' option (transcribe.py error state)")

    def test_transcription_status_no_manual_option(self):
        """'manual' is not a valid transcription status — semantic mismatch."""
        schema = self._load_schema()
        fields = {f["fieldname"]: f for f in schema["fields"]}
        options = fields["transcription_status"]["options"].split("\n")
        self.assertNotIn("manual", options,
                         "'manual' is not a transcription status — should be 'failed'")


if __name__ == "__main__":
    unittest.main()
