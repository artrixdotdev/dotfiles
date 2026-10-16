#!/usr/bin/env python3
"""Connect to an included Tailscale machine with existing SSH trust and keys."""

import argparse
import ipaddress
import json
import os
from pathlib import Path
import stat
import subprocess
import sys


MACHINES = Path(__file__).resolve().parent.parent / "references" / "machines.md"


class ConnectionError(Exception):
    pass


def default_hosts_file() -> Path:
    configured = os.environ.get("SSH_CONNECT_HOSTS_JSON")
    if configured:
        return Path(configured).expanduser()
    for parent in Path(__file__).resolve().parents:
        candidate = parent / ".encrypted" / "tailscale.json"
        if candidate.is_file():
            return candidate
    raise ConnectionError("No hosts JSON found; pass --hosts-file")


def hosts_from_json(path: Path) -> dict[str, str]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ConnectionError("Cannot read hosts JSON") from exc
    if not isinstance(data, dict) or not all(
        isinstance(alias, str) and isinstance(host, str) and alias and host
        for alias, host in data.items()
    ):
        raise ConnectionError("Hosts JSON must map aliases to host names or addresses")
    return data


def excluded_targets() -> set[str]:
    if not MACHINES.is_file():
        return set()
    excluded: set[str] = set()
    heading = None
    for line in MACHINES.read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            heading = line[3:].strip()
        elif line.strip().startswith("- Fleet status: Excluded.") and heading:
            excluded.add(heading)
    return excluded


def tailscale_peer(target: str, configured_host: str) -> tuple[str, str]:
    try:
        result = subprocess.run(
            ["tailscale", "status", "--json"], capture_output=True, text=True, check=True
        )
        status = json.loads(result.stdout)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        raise ConnectionError("Tailscale status is unavailable") from exc

    self_name = status.get("Self", {}).get("DNSName", "").split(".")[0]
    if self_name == target:
        raise ConnectionError("The target is this machine; use a local shell")

    matches = []
    for peer in status.get("Peer", {}).values():
        dns_name = peer.get("DNSName", "").rstrip(".")
        addresses = peer.get("TailscaleIPs", [])
        if configured_host not in (dns_name.split(".")[0], dns_name) and configured_host not in addresses:
            continue
        matches.append(peer)
    if len(matches) != 1:
        raise ConnectionError("Target is absent or ambiguous in Tailscale status")
    peer = matches[0]
    if not peer.get("Online"):
        raise ConnectionError("Target is offline in Tailscale status")
    addresses = peer.get("TailscaleIPs", [])
    ipv4 = []
    for address in addresses:
        try:
            if isinstance(ipaddress.ip_address(address), ipaddress.IPv4Address):
                ipv4.append(address)
        except ValueError:
            continue
    if len(ipv4) != 1:
        raise ConnectionError("Target has no unique Tailscale IPv4 address")
    return ipv4[0], peer.get("DNSName", "").rstrip(".")


def trusted_host_alias(target: str, fqdn: str, address: str) -> str:
    known_hosts = Path.home() / ".ssh" / "known_hosts"
    if not known_hosts.is_file():
        raise ConnectionError("No user SSH known_hosts file; verify the host key first")
    for candidate in (target, fqdn, address):
        if not candidate:
            continue
        result = subprocess.run(
            ["ssh-keygen", "-F", candidate, "-f", str(known_hosts)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if result.returncode == 0:
            return candidate
    raise ConnectionError("No trusted SSH host key for target; verify it first")


def agent_with_identities() -> Path | None:
    candidates = []
    current = os.environ.get("SSH_AUTH_SOCK")
    if current:
        candidates.append(Path(current))
    candidates.extend(sorted(Path.home().glob(".*ssh*agent*.sock")))
    seen = set()
    for path in candidates:
        if path in seen:
            continue
        seen.add(path)
        try:
            if not stat.S_ISSOCK(path.stat().st_mode):
                continue
        except OSError:
            continue
        env = os.environ.copy()
        env["SSH_AUTH_SOCK"] = str(path)
        result = subprocess.run(
            ["ssh-add", "-l"], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        if result.returncode == 0:
            return path
    return None


def identity() -> tuple[dict[str, str], str]:
    agent = agent_with_identities()
    if agent is not None:
        env = os.environ.copy()
        env["SSH_AUTH_SOCK"] = str(agent)
        return env, "SSH agent"
    return os.environ.copy(), "SSH configuration defaults"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="inspect routing, trust, and identity without connecting")
    parser.add_argument("--hosts-file", type=Path, help="JSON mapping aliases to Tailscale host names or addresses")
    parser.add_argument("--allow-excluded", action="store_true", help="permit an excluded target when explicitly requested")
    parser.add_argument("target", help="an alias in the hosts JSON")
    parser.add_argument("command", nargs=argparse.REMAINDER, help="optional remote command after --")
    args = parser.parse_args()

    hosts = hosts_from_json(args.hosts_file or default_hosts_file())
    if args.target not in hosts:
        raise ConnectionError("Target is not present in hosts JSON")
    if not args.allow_excluded and args.target in excluded_targets():
        raise ConnectionError("Target is excluded in the private machine reference")
    address, fqdn = tailscale_peer(args.target, hosts[args.target])
    host_alias = trusted_host_alias(args.target, fqdn, address)
    env, auth_source = identity()
    if args.check:
        print(f"{args.target}: online; host key trusted; authentication via {auth_source}")
        return 0

    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    ssh_args = [
        "ssh",
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=yes",
        "-o", "ConnectTimeout=10",
        "-o", f"HostKeyAlias={host_alias}",
        "-o", f"HostName={address}",
        args.target,
        *command,
    ]
    os.execvpe("ssh", ssh_args, env)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ConnectionError as exc:
        print(f"ssh_connect: {exc}", file=sys.stderr)
        sys.exit(1)
