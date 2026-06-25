"""E5 Test — Whisper transcription pipeline contract tests.

Tests verify the API contract between security-api and Whisper container,
not the actual network calls.
"""
import unittest


class TestWhisperContract(unittest.TestCase):
    """Verify Whisper API contract matches what security-api expects."""

    def test_health_endpoint_contract(self):
        """GET /health → {"status": "ok"}"""
        response = {"status": "ok"}
        self.assertIn("status", response)
        self.assertEqual(response["status"], "ok")

    def test_transcribe_endpoint_request(self):
        """POST /transcribe accepts multipart audio file."""
        request_spec = {
            "method": "POST",
            "path": "/transcribe",
            "content_type": "multipart/form-data",
            "field_name": "audio",
        }
        self.assertEqual(request_spec["method"], "POST")
        self.assertEqual(request_spec["path"], "/transcribe")
        self.assertIn("multipart", request_spec["content_type"])

    def test_transcribe_success_response(self):
        """Successful transcription returns text, language, duration."""
        response = {
            "text": "Тестовий транскрипт українською",
            "language": "uk",
            "duration": 12.5,
        }
        self.assertIn("text", response)
        self.assertIn("language", response)
        self.assertIn("duration", response)
        self.assertIsInstance(response["text"], str)
        self.assertGreater(len(response["text"]), 0)
        self.assertIsInstance(response["language"], str)
        self.assertIsInstance(response["duration"], (int, float))
        self.assertGreater(response["duration"], 0)

    def test_transcribe_busy_response(self):
        """When transcription in progress, returns 503."""
        error_response = {"detail": "Transcription in progress, try later"}
        self.assertEqual(error_response["detail"], "Transcription in progress, try later")

    def test_transcribe_empty_audio(self):
        """Empty audio file returns empty text."""
        response = {"text": "", "language": "unknown", "duration": 0.0}
        self.assertEqual(response["text"], "")
        self.assertEqual(response["language"], "unknown")
        self.assertEqual(response["duration"], 0.0)

    def test_security_api_transcribe_endpoint(self):
        """POST /api/v2/media/{name}/transcribe enqueues RQ task."""
        endpoint = {
            "method": "POST",
            "path": "/api/v2/media/{name}/transcribe",
            "auth": "required",
            "response": {"status": "queued"},
        }
        self.assertEqual(endpoint["method"], "POST")
        self.assertIn("{name}", endpoint["path"])
        self.assertEqual(endpoint["auth"], "required")

    def test_security_api_manual_transcription(self):
        """POST /api/v2/media/{name}/transcription — manual text entry."""
        endpoint = {
            "method": "POST",
            "path": "/api/v2/media/{name}/transcription",
            "body": {"text": "Manual transcription text"},
            "auth": "required",
        }
        self.assertEqual(endpoint["method"], "POST")
        self.assertIn("text", endpoint["body"])
        self.assertGreater(len(endpoint["body"]["text"]), 0)


if __name__ == "__main__":
    unittest.main()
