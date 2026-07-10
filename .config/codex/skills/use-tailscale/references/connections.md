# Connections

Keep this reference generic. Store every machine-specific name, address, alias, role, capability, credential reference, lookup key, and topology detail only in encrypted `machines.md`.

## Connect

Resolve the target and connection parameters from the encrypted machine reference without printing them. Prefer the configured SSH host entry so host verification and authentication settings remain intact.

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
