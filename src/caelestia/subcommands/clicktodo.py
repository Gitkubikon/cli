# clicktodo.py — OCR click-to-copy via Quickshell overlay
#
# This module provides a smooth, flicker-free OCR overlay by delegating
# to the Quickshell shell module which uses Wayland's ScreencopyView.

import os
import subprocess
import sys
import time
from argparse import Namespace


def _is_debug_enabled(args: Namespace | None = None) -> bool:
    env_value = os.getenv("CAELESTIA_DEBUG", "")
    env_enabled = env_value.lower() in {"1", "true", "yes", "on"}
    arg_enabled = bool(getattr(args, "debug", False)) if args is not None else False
    return arg_enabled or env_enabled


def debug_log(enabled: bool, message: str) -> None:
    if enabled:
        print(f"[clicktodo] {message}", flush=True)


def ensure_ocr_service_ready(debug: bool = False):
    """Ensure the OCR daemon is up before launching overlay."""
    try:
        from caelestia.ocr_client import get_ocr_client
    except ImportError:
        raise ImportError("OCR client not available. Please ensure the package is properly installed.")

    start = time.perf_counter()
    client = get_ocr_client()
    debug_log(debug, "Ensuring OCR daemon is ready")

    ensure_daemon = getattr(client, "_ensure_daemon", None)
    if ensure_daemon is None or not callable(ensure_daemon):
        raise RuntimeError("OCR client missing daemon bootstrap helper")

    if not ensure_daemon():
        raise RuntimeError("Could not start OCR daemon. Please install dependencies: pip install rapidocr-onnxruntime")

    elapsed_ms = (time.perf_counter() - start) * 1000
    debug_log(debug, f"OCR daemon ready (warmup took {elapsed_ms:.1f}ms)")

    return client


def warm_up_ocr(client, fast: bool, debug: bool) -> None:
    """Explicitly warm up the OCR daemon to keep models hot."""
    stats = None
    try:
        stats = client.get_stats()
    except Exception as exc:
        debug_log(debug, f"Failed to fetch stats before warm-up: {exc}")

    if stats and stats.get("warmed") and stats.get("requests", 0) > 0:
        debug_log(debug, "Skipping warm-up; daemon already hot")
        return

    try:
        debug_log(debug, f"Running warm-up inference (fast={fast})")
        response = client.warm_up(fast=fast)
        warm_ms = response.get("timing", {}).get("warm")
        if warm_ms is not None:
            debug_log(debug, f"Warm-up completed in {warm_ms:.1f}ms")
    except Exception as exc:
        debug_log(debug, f"Warm-up failed: {exc}")


class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        debug = _is_debug_enabled(self.args)
        fast_mode = getattr(self.args, "fast", False)
        live_mode = getattr(self.args, "live", True)  # Default to live mode for streaming

        try:
            debug_log(debug, f"Fast mode {'enabled' if fast_mode else 'disabled'}")
            debug_log(debug, f"Live mode {'enabled' if live_mode else 'disabled'}")

            # Ensure OCR daemon is ready before launching overlay
            client = ensure_ocr_service_ready(debug=debug)
            warm_up_ocr(client, fast=fast_mode, debug=debug)

            # Determine which shell IPC function to call
            # open/openFast default to streaming (live mode)
            # openBatch/openFastBatch are non-streaming
            if fast_mode:
                ipc_func = "openFast" if live_mode else "openFastBatch"
            else:
                ipc_func = "open" if live_mode else "openBatch"

            debug_log(debug, f"Launching shell overlay via IPC: clicktodo.{ipc_func}")

            # Call the Quickshell module via IPC
            result = subprocess.run(["caelestia", "shell", "clicktodo", ipc_func], capture_output=True, text=True)

            if result.returncode != 0:
                if debug:
                    debug_log(debug, f"Shell call stderr: {result.stderr}")
                # Fall back to error message
                if "not found" in result.stderr.lower() or "unknown" in result.stderr.lower():
                    print("Error: Quickshell module not loaded. Please restart the shell.", file=sys.stderr)
                    sys.exit(1)

        except ImportError as e:
            debug_log(debug, f"Import error: {e}")
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            debug_log(debug, f"Unhandled error: {e}")
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
