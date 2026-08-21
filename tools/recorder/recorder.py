from __future__ import annotations

import signal
from pathlib import Path
from typing import Any

from playwright.sync_api import Browser, Page, Playwright, sync_playwright

from tools.recorder.session import EventType, Locators, RecordingSession, SessionLog
from tools.recorder.trace import TRACE_FILENAME, TraceManager

SESSION_FILENAME = "session.json"

_CAPTURE_INIT_SCRIPT = """
(() => {
  if (window.__bothunterRecorderInstalled) {
    return;
  }
  window.__bothunterRecorderInstalled = true;

  const tagRole = (tagName) => {
    const map = {
      A: "link",
      BUTTON: "button",
      INPUT: "textbox",
      SELECT: "combobox",
      TEXTAREA: "textbox",
    };
    return map[tagName] || null;
  };

  const locatorHints = (element) => {
    if (!element || element.nodeType !== Node.ELEMENT_NODE) {
      return { role: null, test_id: null, css_hint: null };
    }
    const testId =
      element.getAttribute("data-testid") ||
      element.getAttribute("data-qa") ||
      element.getAttribute("data-test-id");
    const explicitRole = element.getAttribute("role");
    const role = explicitRole || tagRole(element.tagName);
    const name =
      element.getAttribute("aria-label") ||
      element.getAttribute("name") ||
      (element.innerText || "").trim().slice(0, 80) ||
      null;
    let cssHint = null;
    if (element.id) {
      cssHint = `#${element.id}`;
    } else if (testId) {
      cssHint = `[data-qa="${testId}"]`;
    }
    return {
      role: role && name ? [role, name] : role ? [role] : null,
      test_id: testId,
      css_hint: cssHint,
    };
  };

  const publish = (payload) => {
    if (typeof window.recordBothunterEvent !== "function") {
      return;
    }
    window.recordBothunterEvent(payload);
  };

  document.addEventListener(
    "click",
    (event) => {
      const target = event.target instanceof Element ? event.target : null;
      publish({
        type: "click",
        url: window.location.href,
        locators: locatorHints(target),
      });
    },
    true,
  );

  document.addEventListener(
    "input",
    (event) => {
      const target = event.target;
      if (!(target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement)) {
        return;
      }
      publish({
        type: "fill",
        url: window.location.href,
        locators: locatorHints(target),
        value: target.value,
      });
    },
    true,
  );

  document.addEventListener(
    "change",
    (event) => {
      const target = event.target;
      if (!(target instanceof HTMLSelectElement)) {
        return;
      }
      publish({
        type: "select",
        url: window.location.href,
        locators: locatorHints(target),
        value: target.value,
      });
    },
    true,
  );

  document.addEventListener(
    "keydown",
    (event) => {
      if (!event.key || event.key.length !== 1) {
        publish({
          type: "keyboard",
          url: window.location.href,
          key: event.key,
        });
      }
    },
    true,
  );
})();
"""


class BrowserRecorder:
    def __init__(
        self,
        output_dir: Path,
        start_url: str,
        *,
        headless: bool = False,
    ) -> None:
        self._output_dir = output_dir
        self._start_url = start_url
        self._headless = headless
        self._session_log = SessionLog(start_url)
        self._trace_manager = TraceManager(output_dir)
        self._stop_requested = False

    @property
    def session_log(self) -> SessionLog:
        return self._session_log

    def run(self) -> RecordingSession:
        self._output_dir.mkdir(parents=True, exist_ok=True)
        previous_handler = signal.getsignal(signal.SIGINT)

        def handle_interrupt(signum: int, frame: Any) -> None:
            self._stop_requested = True

        signal.signal(signal.SIGINT, handle_interrupt)
        try:
            with sync_playwright() as playwright:
                return self._run_browser(playwright)
        finally:
            signal.signal(signal.SIGINT, previous_handler)

    def _run_browser(self, playwright: Playwright) -> RecordingSession:
        browser = playwright.chromium.launch(headless=self._headless)
        context = browser.new_context()
        self._trace_manager.start(context)
        context.expose_binding("recordBothunterEvent", self._handle_browser_event)
        page = context.new_page()
        self._attach_page(page)
        page.goto(self._start_url)
        self._session_log.record(EventType.NAVIGATION, url=page.url)

        try:
            while not self._stop_requested and not page.is_closed():
                page.wait_for_timeout(200)
        finally:
            session = self._finalize(context, browser)
        return session

    def _attach_page(self, page: Page) -> None:
        page.add_init_script(_CAPTURE_INIT_SCRIPT)

        def on_navigated(frame: Any) -> None:
            if frame == page.main_frame:
                self._session_log.record(EventType.NAVIGATION, url=page.url)

        def on_dialog(dialog: Any) -> None:
            self._session_log.record(
                EventType.DIALOG,
                url=page.url,
                dialog_type=dialog.type,
                message=dialog.message,
            )

        page.on("framenavigated", on_navigated)
        page.on("dialog", on_dialog)

    def _handle_browser_event(self, source: Any, payload: dict[str, Any]) -> None:
        page = source.page
        event_type = EventType(payload["type"])
        locators_data = payload.get("locators")
        locators = None
        if locators_data:
            locators = Locators(
                role=locators_data.get("role"),
                test_id=locators_data.get("test_id"),
                css_hint=locators_data.get("css_hint"),
            )
        self._session_log.record(
            event_type,
            url=payload.get("url") or page.url,
            locators=locators,
            value=payload.get("value"),
            key=payload.get("key"),
        )

    def _finalize(self, context: Any, browser: Browser) -> RecordingSession:
        session = self._session_log.finalize()
        session_path = self._output_dir / SESSION_FILENAME
        session.save(session_path)
        self._trace_manager.stop(context)
        browser.close()
        return session


def session_artifacts(output_dir: Path) -> tuple[Path, Path]:
    return output_dir / SESSION_FILENAME, output_dir / TRACE_FILENAME
