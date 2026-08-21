from __future__ import annotations

import json
from pathlib import Path

from tools.recorder.recorder import BrowserRecorder
from tools.recorder.session import (
    EventType,
    Locators,
    RecordingSession,
    SessionEvent,
    SessionLog,
)


def test_session_log_assigns_monotonic_sequence() -> None:
    log = SessionLog("https://example.com")
    first = log.record(EventType.NAVIGATION, url="https://example.com")
    second = log.record(EventType.CLICK, url="https://example.com/a")

    assert first.seq == 1
    assert second.seq == 2
    assert first.timestamp.endswith("Z")
    assert second.timestamp.endswith("Z")


def test_recording_session_round_trip() -> None:
    session = RecordingSession(
        version=1,
        started_at="2026-08-21T10:00:00Z",
        ended_at="2026-08-21T10:05:00Z",
        start_url="https://hh.ru/",
        events=[
            SessionEvent(
                seq=1,
                timestamp="2026-08-21T10:00:01Z",
                type=EventType.NAVIGATION,
                url="https://hh.ru/",
            ),
            SessionEvent(
                seq=2,
                timestamp="2026-08-21T10:00:02Z",
                type=EventType.CLICK,
                url="https://hh.ru/vacancy/1",
                locators=Locators(role=["button", "Откликнуться"], test_id="response"),
            ),
        ],
    )

    payload = session.to_dict()
    restored = RecordingSession.from_dict(payload)

    assert restored == session
    assert payload["events"][1]["locators"]["role"] == ["button", "Откликнуться"]


def test_session_log_finalize_sets_ended_at(tmp_path: Path) -> None:
    log = SessionLog("https://example.com", started_at="2026-08-21T10:00:00Z")
    log.record(EventType.NAVIGATION, url="https://example.com", timestamp="2026-08-21T10:00:01Z")

    session = log.finalize()
    session_path = tmp_path / "session.json"
    session.save(session_path)

    loaded = json.loads(session_path.read_text(encoding="utf-8"))
    assert loaded["version"] == 1
    assert loaded["start_url"] == "https://example.com"
    assert loaded["ended_at"] is not None
    assert len(loaded["events"]) == 1


def test_locators_from_dict_accepts_partial_data() -> None:
    locators = Locators.from_dict({"test_id": "vacancy-response"})
    assert locators.role is None
    assert locators.test_id == "vacancy-response"


def test_browser_recorder_maps_binding_payload() -> None:
    recorder = BrowserRecorder(Path("ignored"), "https://example.com")
    source = type("Source", (), {"page": type("Page", (), {"url": "https://example.com/x"})()})()

    recorder._handle_browser_event(
        source,
        {
            "type": "click",
            "url": "https://example.com/x",
            "locators": {
                "role": ["button", "Search"],
                "test_id": "search",
                "css_hint": "[data-qa=search]",
            },
        },
    )

    events = recorder.session_log.events
    assert len(events) == 1
    assert events[0].type is EventType.CLICK
    assert events[0].locators is not None
    assert events[0].locators.role == ["button", "Search"]
    assert events[0].locators.test_id == "search"
