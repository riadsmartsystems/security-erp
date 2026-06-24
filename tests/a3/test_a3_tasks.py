"""A3 tests — Whisper RQ tasks (transcribe_media, ai_estimate_build).

Run:
  PYTHONPATH=services/security-api:erpnext/security_erp python3 -m unittest tests.a3.test_a3_tasks -v

frappe module is mocked before importing task modules.
"""

import importlib
import json
import os
import sys
import unittest
from unittest.mock import MagicMock, patch

# Ensure paths are importable
_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)

_erpnext_root = os.path.join(os.path.dirname(__file__), "..", "..", "erpnext", "security_erp")
if os.path.isdir(_erpnext_root):
    sys.path.insert(0, _erpnext_root)

# Mock frappe before importing task modules
mock_frappe = MagicMock()
sys.modules["frappe"] = mock_frappe
sys.modules["frappe.utils"] = MagicMock()


def _import_transcribe():
    if "security_erp.tasks.transcribe" in sys.modules:
        return importlib.reload(sys.modules["security_erp.tasks.transcribe"])
    import security_erp.tasks.transcribe
    return security_erp.tasks.transcribe


def _import_ai_estimate():
    # Mock redis so top-level 'import redis' in ai_estimate.py doesn't fail
    if "redis" not in sys.modules:
        sys.modules["redis"] = MagicMock()

    # Mock adapter imports that need httpx (not available in test env)
    for mod_name in [
        "security_erp.ai",
        "security_erp.ai.adapters",
        "security_erp.ai.adapters.base",
        "security_erp.ai.adapters.gemini",
        "security_erp.ai.adapters.stub",
        "security_erp.ai.circuit_breaker",
        "security_erp.ai.orchestrator",
    ]:
        if mod_name not in sys.modules:
            sys.modules[mod_name] = MagicMock()

    # Make @frappe.whitelist() an identity decorator so functions keep real signatures
    mock_frappe.whitelist.return_value = lambda f: f

    if "security_erp.tasks.ai_estimate" in sys.modules:
        return importlib.reload(sys.modules["security_erp.tasks.ai_estimate"])
    import security_erp.tasks.ai_estimate
    return security_erp.tasks.ai_estimate


class TestTranscribeMedia(unittest.TestCase):

    def test_transcribe_success(self):
        mod = _import_transcribe()

        mock_doc = MagicMock()
        mock_doc.drive_file_id = "https://drive.google.com/file/d/abc123/view"
        mock_doc.name = "MA-00001"
        mod.frappe.get_doc.return_value = mock_doc

        mock_requests = MagicMock()
        audio_resp = MagicMock()
        audio_resp.content = b"fake-audio-bytes"
        audio_resp.headers = {"content-type": "audio/ogg"}
        audio_resp.raise_for_status = MagicMock()
        mock_requests.get.return_value = audio_resp

        whisper_resp = MagicMock()
        whisper_resp.json.return_value = {
            "text": "Встановити 8 камер на об'єкті",
            "language": "uk",
            "duration": 12.5,
        }
        whisper_resp.raise_for_status = MagicMock()
        mock_requests.post.return_value = whisper_resp

        with patch.object(mod, "requests", mock_requests):
            result = mod.transcribe_media("MA-00001")

        self.assertEqual(result["status"], "done")
        self.assertEqual(result["text"], "Встановити 8 камер на об'єкті")
        self.assertEqual(result["language"], "uk")
        self.assertEqual(result["duration"], 12.5)
        mock_doc.db_set.assert_any_call("transcription", "Встановити 8 камер на об'єкті", update_modified=False)

    def test_transcribe_no_drive_file_id(self):
        mod = _import_transcribe()

        mock_doc = MagicMock()
        mock_doc.drive_file_id = ""
        mock_doc.name = "MA-00002"
        mod.frappe.get_doc.return_value = mock_doc

        result = mod.transcribe_media("MA-00002")

        self.assertEqual(result["status"], "error")
        self.assertEqual(result["reason"], "no_drive_file_id")

    def test_transcribe_whisper_unavailable(self):
        mod = _import_transcribe()

        mock_doc = MagicMock()
        mock_doc.drive_file_id = "https://drive.google.com/file/d/abc123/view"
        mock_doc.name = "MA-00003"
        mod.frappe.get_doc.return_value = mock_doc

        mock_requests = MagicMock()
        audio_resp = MagicMock()
        audio_resp.content = b"fake-audio"
        audio_resp.headers = {"content-type": "audio/ogg"}
        audio_resp.raise_for_status = MagicMock()
        mock_requests.get.return_value = audio_resp

        conn_err = type("ConnectionError", (Exception,), {})
        mock_requests.exceptions.ConnectionError = conn_err
        mock_requests.post.side_effect = conn_err("Connection refused")

        with patch.object(mod, "requests", mock_requests):
            result = mod.transcribe_media("MA-00003")

        self.assertEqual(result["status"], "error")
        self.assertEqual(result["reason"], "whisper_unavailable")

    def test_transcribe_download_failure(self):
        mod = _import_transcribe()

        mock_doc = MagicMock()
        mock_doc.drive_file_id = "https://drive.google.com/file/d/abc123/view"
        mock_doc.name = "MA-00004"
        mod.frappe.get_doc.return_value = mock_doc

        mock_requests = MagicMock()
        mock_requests.get.side_effect = Exception("404 Not Found")

        with patch.object(mod, "requests", mock_requests):
            result = mod.transcribe_media("MA-00004")

        self.assertEqual(result["status"], "error")
        self.assertIn("download_failed", result["reason"])

    def test_ext_from_content_type(self):
        mod = _import_transcribe()

        self.assertEqual(mod._ext_from_content_type("audio/ogg"), "ogg")
        self.assertEqual(mod._ext_from_content_type("audio/mpeg"), "mp3")
        self.assertEqual(mod._ext_from_content_type("audio/wav"), "wav")
        self.assertEqual(mod._ext_from_content_type("audio/webm"), "webm")
        self.assertEqual(mod._ext_from_content_type("application/octet-stream"), "ogg")


class TestAIEstimateBuild(unittest.TestCase):
    """Tests for run_ai_estimate (RQ worker) and enqueue_ai_estimate (Frappe-whitelist entrypoint).

    Replaces the original tests that targeted ai_estimate_build/_write_ai_request_log
    (functions that never existed in the current implementation).
    """

    def test_run_ai_estimate_skips_non_draft(self):
        """run_ai_estimate must return immediately when status != Draft."""
        mod = _import_ai_estimate()

        mock_doc = MagicMock()
        mock_doc.status = "Approved"
        mod.frappe.get_doc.return_value = mock_doc

        with patch.object(mod, "_run_orchestrator_sync") as mock_orch:
            mod.run_ai_estimate("EST-00001")
            mock_orch.assert_not_called()

    def test_run_ai_estimate_success_sets_ai_draft(self):
        """Successful AI result → status='AI Draft', origin='ai_primary'."""
        mod = _import_ai_estimate()
        mod.frappe.db.reset_mock()

        mock_doc = MagicMock()
        mock_doc.status = "Draft"
        mock_doc.object_type = "Warehouse"
        mock_doc.area_sqm = 200
        mock_doc.cameras_count = 8
        mock_doc.archive_days = 14
        mock_doc.scenario = "optimal"
        mod.frappe.get_doc.return_value = mock_doc

        mock_result = MagicMock()
        mock_result.content = '{"items": [{"item_code": "CAM-4MP", "qty": 8}]}'
        mock_result.provider = "gemini"

        with patch.object(mod, "_run_orchestrator_sync", return_value=mock_result):
            mod.run_ai_estimate("EST-00001")

        mod.frappe.db.set_value.assert_called_once()
        call_data = mod.frappe.db.set_value.call_args[0][2]
        self.assertEqual(call_data["origin"], "ai_primary")
        self.assertEqual(call_data["status"], "AI Draft")

    def test_run_ai_estimate_manual_fallback(self):
        """All providers failed ([MANUAL] prefix) → origin='manual', status='Draft'."""
        mod = _import_ai_estimate()

        mock_doc = MagicMock()
        mock_doc.status = "Draft"
        mock_doc.object_type = "Office"
        mock_doc.area_sqm = 50
        mock_doc.cameras_count = 4
        mock_doc.archive_days = 7
        mock_doc.scenario = "basic"
        mod.frappe.get_doc.return_value = mock_doc

        mock_result = MagicMock()
        mock_result.content = "[MANUAL] All AI providers failed."
        mock_result.provider = "none"

        with patch.object(mod, "_run_orchestrator_sync", return_value=mock_result):
            mod.run_ai_estimate("EST-00002")

        call_data = mod.frappe.db.set_value.call_args[0][2]
        self.assertEqual(call_data["origin"], "manual")
        self.assertEqual(call_data["status"], "Draft")

    def test_enqueue_ai_estimate_delegates_to_frappe_enqueue(self):
        """enqueue_ai_estimate must call frappe.enqueue with run_ai_estimate path."""
        mod = _import_ai_estimate()
        mod.frappe.enqueue.reset_mock()

        mod.enqueue_ai_estimate("EST-00003", "site brief text", "standard")

        mod.frappe.enqueue.assert_called_once()
        task_path = mod.frappe.enqueue.call_args[0][0]
        self.assertIn("run_ai_estimate", task_path)
        kwargs = mod.frappe.enqueue.call_args[1]
        self.assertEqual(kwargs["estimate_name"], "EST-00003")


class TestWhisperHealthcheck(unittest.TestCase):

    def test_health_response_schema(self):
        expected_keys = {"status", "model", "device"}
        mock_response = {"status": "ok", "model": "medium", "device": "cpu"}
        self.assertEqual(set(mock_response.keys()), expected_keys)
        self.assertEqual(mock_response["status"], "ok")


if __name__ == "__main__":
    unittest.main()
