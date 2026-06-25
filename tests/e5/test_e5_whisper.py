"""E5 Whisper integration tests."""
import asyncio, os, sys, unittest
from unittest.mock import patch, AsyncMock

_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root): sys.path.insert(0, _services_root)

def _run(coro):
    loop = asyncio.new_event_loop()
    try: return loop.run_until_complete(coro)
    finally: loop.close()

class TestWhisperTranscription(unittest.TestCase):
    def test_transcribe_endpoint_calls_rq(self):
        from app.services.media_service import enqueue_transcription
        with patch("app.services.media_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.media_service.frappe_post", new_callable=AsyncMock) as mock_post:
            mock_get.return_value = {"data": {"name": "MEDIA-001", "drive_file_id": "drive-123"}}
            mock_post.return_value = {"message": "queued"}
            # enqueue_transcription returns None, so we just check it doesn't raise
            _run(enqueue_transcription(sid="sid", name="MEDIA-001"))
            mock_get.assert_called_once()
            mock_post.assert_called_once()

    def test_transcription_status_update(self):
        from app.services.media_service import save_manual_transcription
        with patch("app.services.media_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.media_service.frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.return_value = {"data": {"name": "MEDIA-002"}}
            mock_put.return_value = {"data": {}}
            _run(save_manual_transcription(sid="sid", name="MEDIA-002", text="Test"))
            mock_get.assert_called_once()
            mock_put.assert_called_once()

if __name__ == "__main__": unittest.main()
