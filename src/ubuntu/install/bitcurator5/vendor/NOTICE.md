# Third-Party Notice: BitCurator

The files under this `vendor/` directory (nautilus scripts, `.vimrc`/vim
colors, `run-*.sh` tool launchers, the BitCurator menu/icon set, the
`bc_mounter.py`/`bc_policyapp.py` mount-policy apps, and the bundled
documentation) are copied, with only the minimal changes noted below, from:

- Project: **BitCurator** — https://bitcurator.github.io/
- Source repository: https://github.com/BitCurator/bitcurator-salt
- License: **GNU General Public License v3.0** (see `LICENSE-GPLv3.txt` in
  this directory for the full text)

`src/ubuntu/install/bitcurator5/packages.sh`, `build_tools.sh`, and
`python_tools.sh` in the parent directory are SquirrelWorks' own
reimplementation of the *logic* described by bitcurator-salt's SaltStack
states (which package/build/pip steps to run) as plain bash, written to run
correctly in a Kasm container where Salt, systemd, and a dedicated desktop
user are not available. They are not copies of bitcurator-salt's `.sls`
files.

## Changes from upstream

- `menu-config/gtkhash.desktop` was renamed from upstream's
  `gtkhash:gtkhash.desktop` — NTFS/Windows cannot hold a `:` in a filename.
  The file's contents are unchanged; the filename has no effect on how the
  desktop menu registers it.
- Nothing else in this directory has been modified from upstream.

## Why this exists

BitCurator officially ships via its own `bitcurator-cli` (SaltStack)
installer, which assumes a full, dedicated Ubuntu Desktop install with
systemd and a real login session. That doesn't hold in a Kasm container
build, and repeated attempts to work around the mismatch (systemd shims,
root/sudo detection conflicts, uid-aliasing to satisfy Salt's user-management
states) kept surfacing new failures. Vendoring BitCurator's own static assets
and package list directly - and reimplementing the install steps in plain
bash - removes the SaltStack/systemd dependency entirely while still
shipping the genuine BitCurator desktop experience (menus, tools, nautilus
scripts, documentation).
