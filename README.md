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

The NeoWall user service selects its shader frame policy from system battery and
GPU detection at startup. Run `nu setup.nu post` to install and enable user
services, then restart changed services after an update.
