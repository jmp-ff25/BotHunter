from __future__ import annotations

import json
from dataclasses import dataclass, field
from datetime import UTC, datetime
from enum import StrEnum
from pathlib import Path
from typing import Any


class EventType(StrEnum):
    NAVIGATION = "navigation"
    CLICK = "click"
    FILL = "fill"
    SELECT = "select"
    KEYBOARD = "keyboard"
    DIALOG = "dialog"


SESSION_VERSION = 1


@dataclass
class Locators:
    role: list[str] | None = None
    test_id: str | None = None
    css_hint: str | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "role": self.role,
            "test_id": self.test_id,
            "css_hint": self.css_hint,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> Locators:
        role = data.get("role")
        return cls(
            role=list(role) if role is not None else None,
            test_id=data.get("test_id"),
            css_hint=data.get("css_hint"),
        )


@dataclass
class SessionEvent:
    seq: int
    timestamp: str
    type: EventType
    url: str | None = None
    locators: Locators | None = None
    value: str | None = None
    key: str | None = None
    dialog_type: str | None = None
    message: str | None = None
    screenshot_ref: str | None = None

    def to_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "seq": self.seq,
            "timestamp": self.timestamp,
            "type": self.type.value,
        }
        if self.url is not None:
            payload["url"] = self.url
        if self.locators is not None:
            payload["locators"] = self.locators.to_dict()
        if self.value is not None:
            payload["value"] = self.value
        if self.key is not None:
            payload["key"] = self.key
        if self.dialog_type is not None:
            payload["dialog_type"] = self.dialog_type
        if self.message is not None:
            payload["message"] = self.message
        if self.screenshot_ref is not None:
            payload["screenshot_ref"] = self.screenshot_ref
        return payload

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> SessionEvent:
        locators_data = data.get("locators")
        return cls(
            seq=int(data["seq"]),
            timestamp=str(data["timestamp"]),
            type=EventType(data["type"]),
            url=data.get("url"),
            locators=Locators.from_dict(locators_data) if locators_data else None,
            value=data.get("value"),
            key=data.get("key"),
            dialog_type=data.get("dialog_type"),
            message=data.get("message"),
            screenshot_ref=data.get("screenshot_ref"),
        )


@dataclass
class RecordingSession:
    version: int
    started_at: str
    ended_at: str | None
    start_url: str
    events: list[SessionEvent] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "version": self.version,
            "started_at": self.started_at,
            "ended_at": self.ended_at,
            "start_url": self.start_url,
            "events": [event.to_dict() for event in self.events],
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> RecordingSession:
        return cls(
            version=int(data["version"]),
            started_at=str(data["started_at"]),
            ended_at=data.get("ended_at"),
            start_url=str(data["start_url"]),
            events=[SessionEvent.from_dict(item) for item in data.get("events", [])],
        )

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(self.to_dict(), indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

    @classmethod
    def load(cls, path: Path) -> RecordingSession:
        return cls.from_dict(json.loads(path.read_text(encoding="utf-8")))


def utc_now_iso() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


class SessionLog:
    def __init__(self, start_url: str, *, started_at: str | None = None) -> None:
        self._start_url = start_url
        self._started_at = started_at or utc_now_iso()
        self._ended_at: str | None = None
        self._events: list[SessionEvent] = []
        self._seq = 0

    @property
    def events(self) -> list[SessionEvent]:
        return list(self._events)

    def record(
        self,
        event_type: EventType,
        *,
        url: str | None = None,
        locators: Locators | None = None,
        value: str | None = None,
        key: str | None = None,
        dialog_type: str | None = None,
        message: str | None = None,
        screenshot_ref: str | None = None,
        timestamp: str | None = None,
    ) -> SessionEvent:
        self._seq += 1
        event = SessionEvent(
            seq=self._seq,
            timestamp=timestamp or utc_now_iso(),
            type=event_type,
            url=url,
            locators=locators,
            value=value,
            key=key,
            dialog_type=dialog_type,
            message=message,
            screenshot_ref=screenshot_ref,
        )
        self._events.append(event)
        return event

    def finalize(self) -> RecordingSession:
        self._ended_at = utc_now_iso()
        return RecordingSession(
            version=SESSION_VERSION,
            started_at=self._started_at,
            ended_at=self._ended_at,
            start_url=self._start_url,
            events=list(self._events),
        )
