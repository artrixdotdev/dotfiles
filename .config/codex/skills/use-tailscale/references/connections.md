# Connections

Keep this reference generic. Store every machine-specific name, address, alias, role, capability, credential reference, lookup key, and topology detail only in encrypted `machines.md`.

## Connect

Resolve the target and connection parameters from the encrypted machine reference without printing them. Prefer the configured SSH host entry so host verification and authentication settings remain intact.

For configured machines, the skill's `scripts/ssh_connect.py` reads the encrypted Tailscale hosts JSON, resolves the live Tailscale address, checks an existing known-host entry, and finds an agent with identities. SSH config still determines which private key file to use. The helper accepts `--hosts-file` or the `SSH_CONNECT_HOSTS_JSON` environment variable for another JSON mapping. Use it when available, especially if the plain alias fails to resolve or the default SSH agent is empty. The manual steps below remain useful for diagnosis or machines outside that helper's scope.

For the same command on multiple machines, pass comma-separated aliases as one target argument followed by `-- <command>`. The helper checks every target before starting any SSH process, launches the commands concurrently, prefixes output with the target alias, and returns failure if any target fails. Multi-target interactive shells are not supported. Apply the same authorization and scope checks to the command on every target.

For an interactive session:

```sh
ssh <target>
```

For a single command:

```sh
ssh <target> -- <command>
```

Use a TTY only when the remote operation requires one:

```sh
ssh -tt <target> -- <command>
```

## Diagnose connectivity

Check each layer in order:

1. Confirm the local Tailscale client is connected.
2. Test private-network reachability to the selected target.
3. Test non-interactive SSH authentication.
4. Use verbose SSH diagnostics only when necessary.

Distinguish network failure, host verification, authentication, and remote authorization failures. Do not alter network configuration, SSH services, firewalls, or keys unless the user explicitly asks.

## Known-host fallback when aliases do not resolve

If Tailscale shows the selected machine as reachable but the local SSH alias does not resolve, obtain its current address from `tailscale status` and connect with that address as `HostName`. Set `HostKeyAlias` to the already trusted alias so OpenSSH checks the existing known-host entry. First confirm that `ssh-keygen -F <alias>` finds a trusted key. Do not set `StrictHostKeyChecking=no`, accept a new key without verification, or hard-code a Tailscale address that can change.

```sh
target=<alias from machines.md>
target_ip=$(tailscale status | awk -v target="$target" '$2 == target {print $1}')
ssh -o HostKeyAlias="$target" -o HostName="$target_ip" "$target"
```

Check that the lookup returned exactly one address before connecting. This fallback changes name resolution only; SSH authentication still needs an available identity.

## SSH identities

If keys are held by a desktop password manager, the default `SSH_AUTH_SOCK` may point to another agent with no identities. Locate the password manager's agent socket using the machine reference, then use `SSH_AUTH_SOCK=<socket> ssh-add -l` to confirm the identities before connecting. The SSH agent can sign authentication requests but cannot export private key material. A password manager CLI may have a separate lock state from its desktop app and agent.

Keys stored under nondefault filenames on a remote machine are not automatically tried by `ssh <alias>`. Check `ssh -G <alias>` for `identityfile` and add a scoped `Host <alias>` entry with the appropriate `IdentityFile` and `IdentitiesOnly yes` when the user wants that command to work. Preserve existing identity files and verify the exact command after editing.

When the user explicitly asks to place private keys on another machine, use a vault export path rather than trying to extract them from the SSH agent. Keep vault tokens and key bytes out of tool output and command arguments. Prefer streaming each key over an authenticated, host-verified SSH connection into a new temporary file under the target `~/.ssh` with `umask 077`; derive its public fingerprint with `ssh-keygen -y`, compare it with the vault public key, then move it to a distinct final filename. Confirm owner and mode `600`, preserve existing keys, and remove any temporary vault session material after verification. Do not assume this transfer also configures SSH to select the new files.

Some fleet machines use Nushell as their login shell. For remote scripts that require POSIX shell syntax, explicitly invoke `bash -lc` and quote the script for the remote shell. A remote `find` or `awk` may otherwise resolve to a Nushell command or be parsed differently.
