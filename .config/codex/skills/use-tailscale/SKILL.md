---
name: use-tailscale
description: Safely reach and operate a remote computer over Tailscale and SSH. Use when a task requires private-network remote access or when diagnosing Tailscale and SSH connectivity.
---

# Use Tailscale

Read [references/connections.md](references/connections.md) for the generic connection workflow. Read the encrypted [references/machines.md](references/machines.md) when selecting a target or resolving any machine-specific value. Never copy details from the encrypted reference into unencrypted files, logs, commits, or responses.

For machines listed in the encrypted Tailscale hosts JSON, use [scripts/ssh_connect.py](scripts/ssh_connect.py) after selecting targets from the machine reference. Run `python3 ~/.codex/skills/use-tailscale/scripts/ssh_connect.py --check <target>` to inspect readiness, `python3 ~/.codex/skills/use-tailscale/scripts/ssh_connect.py <target> -- <command>` for one remote command, or pass comma-separated targets such as `<target1>,<target2> -- <command>` to run the command concurrently on both. Omit the command for an interactive shell on one target. Multi-target output is labeled by machine, and the helper exits nonzero if any command fails. The helper resolves current Tailscale addresses, requires existing trusted SSH host keys, and uses SSH configuration plus an available agent. It refuses targets marked excluded in the machine reference unless `--allow-excluded` is explicitly passed for an authorized task. It never enrolls new host keys.

## Workflow

1. Determine whether remote access is necessary.
2. Select the least-privileged appropriate target using only the encrypted machine reference.
3. Check reachability when connectivity is uncertain.
4. Connect with the SSH configuration recorded in the encrypted machine reference.
5. Start with read-only inspection.
6. Explain and obtain any required approval before destructive commands, privilege escalation, service disruption, package installation, or changes outside the user's stated scope.
7. Report relevant work without revealing private network or machine details.

## Guardrails

- Treat private network configuration, endpoint values, machine metadata, authentication material, and encrypted references as secret.
- Never commit decrypted private-network or machine information.
- Never weaken host-key checking.
- Do not assume elevated access or authorization to alter a remote system.
- Do not probe systems unrelated to the task.
- Stop and report the failing connection layer without exposing private values.
