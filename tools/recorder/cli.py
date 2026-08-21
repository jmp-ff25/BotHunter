from __future__ import annotations

import argparse
import sys
from pathlib import Path

from tools.recorder.recorder import BrowserRecorder, session_artifacts


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="bothunter-recorder",
        description="Record browser sessions for BotHunter HH exploration.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    record = subparsers.add_parser("record", help="Record a browser session.")
    record.add_argument(
        "--output-dir",
        required=True,
        type=Path,
        help="Directory for session.json and trace.zip.",
    )
    record.add_argument(
        "--start-url",
        required=True,
        help="Initial URL to open in the browser.",
    )
    record.add_argument(
        "--headless",
        action="store_true",
        help="Run the browser in headless mode.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.command == "record":
        recorder = BrowserRecorder(
            output_dir=args.output_dir,
            start_url=args.start_url,
            headless=args.headless,
        )
        session = recorder.run()
        session_path, trace_path = session_artifacts(args.output_dir)
        print(f"Recorded {len(session.events)} events.")
        print(f"Session: {session_path}")
        print(f"Trace: {trace_path}")
        return 0

    parser.error(f"Unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    sys.exit(main())
