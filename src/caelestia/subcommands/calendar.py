import json
import shutil
import subprocess
import sys
from argparse import Namespace
from datetime import datetime, timedelta

DATE_FMT = "%d/%m/%Y"
INPUT_FMT = "%Y-%m-%d"


class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        if not shutil.which("khal"):
            print("khal is not installed; install the 'khal' package to enable calendar commands.", file=sys.stderr)
            return

        start = self._parse_start()
        end = start + timedelta(days=max(self.args.days, 1) - 1)

        try:
            raw = subprocess.check_output(
                [
                    "khal",
                    "list",
                    "--json",
                    "title",
                    "--json",
                    "start-date",
                    "--json",
                    "start-time",
                    "--json",
                    "end-time",
                    start.strftime(DATE_FMT),
                    end.strftime(DATE_FMT),
                ],
                text=True,
            )
        except subprocess.CalledProcessError as e:
            print(f"Failed to read events from khal (exit {e.returncode}).", file=sys.stderr)
            return

        events = self._parse_events(raw)
        if self.args.json:
            print(json.dumps(events, default=str))
        else:
            for event in events:
                print(self._format_event(event))

    def _parse_start(self) -> datetime:
        if self.args.start:
            try:
                return datetime.strptime(self.args.start, INPUT_FMT)
            except ValueError:
                print(f"Invalid start date '{self.args.start}', expected YYYY-MM-DD. Falling back to today.", file=sys.stderr)
        return datetime.now()

    def _parse_events(self, text: str) -> list[dict]:
        events: list[dict] = []
        for line in text.splitlines():
            line = line.strip()
            if not line or line == "[]":
                continue
            try:
                day_events = json.loads(line)
            except json.JSONDecodeError:
                continue

            for evt in day_events:
                start_date = evt.get("start-date")
                if not start_date:
                    continue

                start_time_str = evt.get("start-time") or "00:00"
                end_time_str = evt.get("end-time") or "23:59"

                try:
                    day = datetime.strptime(start_date, DATE_FMT)
                except ValueError:
                    continue

                start_dt = self._combine_date_time(day, start_time_str)
                end_dt = self._combine_date_time(day, end_time_str)

                events.append(
                    {
                        "title": evt.get("title", ""),
                        "start": start_dt.isoformat(),
                        "end": end_dt.isoformat(),
                    }
                )
        return events

    def _combine_date_time(self, date_obj: datetime, time_str: str) -> datetime:
        """Combines a date object with a time string (HH:MM or HH:MM AM/PM)."""
        time_obj = None
        for fmt in ("%H:%M", "%I:%M %p", "%I:%M%p"):
            try:
                time_obj = datetime.strptime(time_str, fmt).time()
                break
            except ValueError:
                continue
        
        if time_obj is None:
            # Fallback for empty or malformed strings, though khal usually provides something valid or we defaulted
            # If the string was empty in original code it defaulted to 00:00 / 23:59 which matches %H:%M
            # But if it fails everything, default to 00:00
            time_obj = datetime.strptime("00:00", "%H:%M").time()

        return datetime.combine(date_obj.date(), time_obj)

    def _format_event(self, event: dict) -> str:
        try:
            start = datetime.fromisoformat(event["start"])
            end = datetime.fromisoformat(event["end"])
        except Exception:
            return f"{event.get('title', '')}"

        start_fmt = start.strftime("%Y-%m-%d %H:%M")
        end_fmt = end.strftime("%Y-%m-%d %H:%M")
        title = event.get("title", "")
        return f"{start_fmt} -> {end_fmt}  {title}"
