from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from playwright.sync_api import BrowserContext


TRACE_FILENAME = "trace.zip"


class TraceManager:
    def __init__(self, output_dir: Path) -> None:
        self._output_dir = output_dir
        self._trace_path = output_dir / TRACE_FILENAME
        self._started = False

    @property
    def trace_path(self) -> Path:
        return self._trace_path

    def start(self, context: BrowserContext) -> None:
        self._output_dir.mkdir(parents=True, exist_ok=True)
        context.tracing.start(screenshots=True, snapshots=True, sources=True)
        self._started = True

    def stop(self, context: BrowserContext) -> Path | None:
        if not self._started:
            return None
        context.tracing.stop(path=str(self._trace_path))
        self._started = False
        return self._trace_path if self._trace_path.exists() else None
