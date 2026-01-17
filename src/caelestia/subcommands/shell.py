import os
import subprocess
from argparse import Namespace

from caelestia.utils.paths import c_cache_dir


class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def _plugin_env(self) -> dict[str, str]:
        env = os.environ.copy()
        paths: list[str] = []

        # Honour explicit overrides first
        for candidate in (
            env.get("CAELESTIA_QT_PLUGIN_DIR"),
            self._plugin_dir_from_qtpaths("qtpaths6"),
            self._plugin_dir_from_qtpaths("qtpaths"),
            "/usr/lib/qt6/plugins",
            "/usr/lib64/qt6/plugins",
            "/lib/qt6/plugins",
            "/usr/lib/qt/plugins",
            "/usr/lib64/qt/plugins",
            "/app/lib/qt6/plugins",
        ):
            if candidate and os.path.isdir(candidate):
                paths.append(candidate)

        if env.get("QT_PLUGIN_PATH"):
            paths.append(env["QT_PLUGIN_PATH"])

        if paths:
            # Deduplicate while preserving order
            seen = set()
            env["QT_PLUGIN_PATH"] = os.pathsep.join(p for p in paths if not (p in seen or seen.add(p)))
        else:
            env.pop("QT_PLUGIN_PATH", None)
        return env

    @staticmethod
    def _plugin_dir_from_qtpaths(bin_name: str) -> str | None:
        try:
            out = subprocess.check_output([bin_name, "--plugin-dir"], text=True).strip()
            return out or None
        except (FileNotFoundError, subprocess.CalledProcessError):
            return None

    def run(self) -> None:
        if self.args.show:
            # Print the ipc
            self.print_ipc()
        elif self.args.log:
            # Print the log
            self.print_log()
        elif self.args.kill:
            # Kill the shell
            self.shell("kill")
        elif self.args.message:
            # Send a message
            self.message(*self.args.message)
        else:
            # Start the shell
            args = ["qs", "-c", "caelestia", "-n"]
            if self.args.log_rules:
                args.extend(["--log-rules", self.args.log_rules])
            if self.args.daemon:
                args.append("-d")
                subprocess.run(args, env=self._plugin_env())
            else:
                shell = subprocess.Popen(args, stdout=subprocess.PIPE, universal_newlines=True, env=self._plugin_env())
                for line in shell.stdout:
                    if self.filter_log(line):
                        print(line, end="")

    def shell(self, *args: list[str]) -> str:
        return subprocess.check_output(["qs", "-c", "caelestia", *args], text=True, env=self._plugin_env())

    def filter_log(self, line: str) -> bool:
        return f"Cannot open: file://{c_cache_dir}/imagecache/" not in line

    def print_ipc(self) -> None:
        print(self.shell("ipc", "show"), end="")

    def print_log(self) -> None:
        if self.args.log_rules:
            log = self.shell("log", "-r", self.args.log_rules)
        else:
            log = self.shell("log")
        # FIXME: remove when logging rules are added/warning is removed
        for line in log.splitlines():
            if self.filter_log(line):
                print(line)

    def message(self, *args: list[str]) -> None:
        print(self.shell("ipc", "call", *args), end="")
