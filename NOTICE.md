# NOTICE

This package is a **repack of a third-party plugin**, published so that it can be
installed with the ordinary dsh plugin command.

## Upstream

- Project: `dsh-browser` — <https://github.com/Lum1104/dsh-browser>
- Plugin package: `@yuxianglin/dsh-bridge-browser` (upstream keeps `"private": true`
  and is **not** published to npm; upstream ships it through `scripts/install.ps1`,
  which also builds the browser extension)
- Author: Yuxiang Lin
- License: MIT (see `LICENSE`, kept verbatim)

## What this repack changes

1. **Package identity.** Published under the `@shallbay` scope as
   `@shallbay/dsh-bridge-browser`, with `"private"` removed,
   so `dsh plugin add` can resolve it from the registry. The plugin's internal
   identity (`export const name = 'bridge-browser'`) is unchanged.
2. **Peer ranges widened** from `^0.1.x-rc.n` to `>=0.1.7-rc.2 <0.3.0`.
   This matters: dsh refuses to install a plugin whose `@deepseek-ai/dsh*`
   peerDependencies do not satisfy the running runtime, so the upstream range makes
   the plugin uninstallable on DSH Desktop 2.x even though the code supports it.
   The code carries the upstream `open.length >= 5` gateway branch, which handles both
   the 0.1.x and the Desktop 2.x `wireStream.open` signatures.
3. **Browser extension bundled** under `extension/`, so a single package delivers both
   halves (the WebSocket bridge plugin and the MV3 extension).
4. **Extension discovery list extended** with `19387` — the port the DSH Desktop host
   listens on (`bs=[19387,3080,3081,3090,14389,43189]`). Upstream probes only
   `3080/3081/3090/14389/43189`, so with upstream's build a Desktop user must type the
   bridge address by hand.
5. Build and test scripts, `devDependencies` and tsbuildinfo removed from the tarball.

## What this repack does NOT change

Runtime behaviour. `lib/` is built from upstream `main` (`tsc -b && tsdown`) with no
source edits beyond the identity fields.

## Maintenance

Upstream owns the code. If you re-run the upstream installer it will rebuild the plugin
and the extension without the widening and without the extra discovery port, so this
repack must be regenerated from upstream `main` after such an update.
