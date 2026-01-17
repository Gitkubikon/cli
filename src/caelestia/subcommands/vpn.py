import os
import subprocess
from argparse import Namespace
from pathlib import Path

class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args
        self.vpn_dir = Path.home() / ".vpn"
        self.pass_file = self.vpn_dir / "pass.txt"

    def run(self) -> None:
        if not self.vpn_dir.exists():
            print(f"Error: {self.vpn_dir} does not exist.")
            return

        if self.args.disconnect:
            # Use pkexec with the full path to pkill
            # We use pkill -f to be more certain
            print("Requesting disconnect...")
            try:
                subprocess.run(["pkexec", "pkill", "openvpn"], check=True)
                print("Disconnected from VPN.")
            except subprocess.CalledProcessError as e:
                # If pkexec returns 127 or 126 it might be missing, but 1 usually means cancelled/denied
                print(f"Failed to disconnect: {e}")
            return

        if not self.pass_file.exists() or self.pass_file.stat().st_size == 0:
            print(f"Error: {self.pass_file} is empty or missing.")
            print(f"Please add your credentials to {self.pass_file} (Username on line 1, Password on line 2).")
            return

        # List .ovpn files
        ovpn_files = list(self.vpn_dir.glob("*.ovpn"))
        if not ovpn_files:
            print(f"No .ovpn files found in {self.vpn_dir}")
            return

        ovpn_names = sorted([f.name for f in ovpn_files])
        
        try:
            # Use fuzzel (GUI) instead of fzf (terminal)
            fuzzel_process = subprocess.Popen(
                ["fuzzel", "--dmenu", "--placeholder=Select VPN Server", "--index"],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                text=True
            )
            stdout, _ = fuzzel_process.communicate(input="\n".join(ovpn_names))
            
            if stdout.strip():
                idx = int(stdout.strip())
                selected = ovpn_names[idx]
                
                print(f"Connecting to {selected}...")
                # Use sh -c to redirect stdin and force GUI Polkit
                cmd = [
                    "sh", "-c",
                    f"pkexec openvpn --config '{self.vpn_dir / selected}' --auth-user-pass '{self.pass_file}' --daemon < /dev/null"
                ]
                subprocess.run(cmd, check=True)
                print("VPN started in background.")
            else:
                print("No selection made.")
        except (subprocess.CalledProcessError, FileNotFoundError, ValueError) as e:
            print(f"Action cancelled or error: {e}")
