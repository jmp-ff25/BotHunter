from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock, patch

from tools.recorder.recorder import BrowserRecorder, session_artifacts
from tools.recorder.session import EventType
from tools.recorder.trace import TraceManager


def test_trace_manager_starts_and_stops(tmp_path: Path) -> None:
    context = MagicMock()
    trace_path = tmp_path / "trace.zip"
    context.tracing.stop.side_effect = lambda path: trace_path.write_bytes(b"trace")

    manager = TraceManager(tmp_path)
    manager.start(context)
    result = manager.stop(context)

    context.tracing.start.assert_called_once()
    context.tracing.stop.assert_called_once_with(path=str(trace_path))
    assert result == trace_path


@patch("tools.recorder.recorder.sync_playwright")
def test_browser_recorder_writes_session_and_trace(mock_sync_playwright, tmp_path: Path) -> None:
    page = MagicMock()
    page.url = "https://example.com"
    page.is_closed.side_effect = [False, False, True]

    context = MagicMock()
    context.new_page.return_value = page

    browser = MagicMock()
    browser.new_context.return_value = context

    playwright = MagicMock()
    playwright.chromium.launch.return_value = browser
    mock_sync_playwright.return_value.__enter__.return_value = playwright

    trace_path = tmp_path / "trace.zip"
    context.tracing.stop.side_effect = lambda path: trace_path.write_bytes(b"trace")

    recorder = BrowserRecorder(tmp_path, "https://example.com", headless=True)
    session = recorder.run()

    session_path, expected_trace_path = session_artifacts(tmp_path)
    assert session_path.exists()
    assert expected_trace_path.exists()
    assert session.start_url == "https://example.com"
    assert any(event.type is EventType.NAVIGATION for event in session.events)
    page.goto.assert_called_once_with("https://example.com")
    browser.close.assert_called_once()
