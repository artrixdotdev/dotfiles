# dotfiles

To install dependencies:

```bash
bun install
```

To run:

```bash
bun run index.ts
```

This project was created using `bun init` in bun v1.2.2. [Bun](https://bun.sh) is a fast all-in-one JavaScript runtime.


## Warning
Migrating to Dank Material Shell ATM!

## Shared desktop configuration

`setup.nu sync` links shared Niri and Dank Material Shell settings from this repo.
Dank Material Shell's `settings.json` and `monitors.json` contain profiles for
both machines. The generated `~/.config/niri/dms/outputs.kdl` stays local to each
machine; setup preserves an existing layout when migrating an older whole-directory
Niri symlink. Run `nu setup.nu sync` on each machine after updating the repo.
Sync also writes a machine-local `~/.config/niri/dms/ssh-agent.kdl` and points
`~/.local/state/dotfiles/ssh-agent.sock` at the available agent socket. Niri and
Codex use that stable path while each machine keeps its own agent.

NeoWall uses display-synced animation on both machines. Its visibility service
pauses the shader at low battery or in power-saver mode on laptops. Run
`nu setup.nu post` to install and enable user services, then restart changed
services after an update.

On laptops, the same service removes Niri blur and sets window opacity to 1 in
power-saver mode. It writes a machine-local DMS `config.d` override for opaque
shell surfaces; the shared `settings.json` retains the normal appearance.
The Niri blur and opacity rules live in `config/power-*.kdl` and are copied to
machine-local `dms/power-*.kdl` files by `setup.nu sync`.
