# nvim-surround Migration Design

## Goal

Replace `tpope/vim-surround` with `kylechui/nvim-surround`, enable its default
configuration and keymaps, and make the repository's `lazy-lock.json` the
active lockfile.

## Configuration Changes

- Change the Home Manager `nvim` config entry to an out-of-store symlink so
  `lazy.nvim` can update the tracked lockfile.
- Remove the custom state-directory lockfile path from `lazy.nvim`. Its default
  path, `stdpath('config') .. '/lazy-lock.json'`, will then resolve to the
  repository-managed file through the symlink.
- Replace the `tpope/vim-surround` plugin spec with
  `kylechui/nvim-surround` and `opts = {}`. No custom mappings or options will
  be added, so the plugin's standard behavior remains active.
- Refresh `lazy-lock.json` to remove obsolete entries and pin the revisions for
  the complete current plugin specification, including `nvim-surround`.
- Align Biome's formatting for `lazy-lock.json` with lazy.nvim's generated
  layout so plugin operations do not create format-only diffs.

## Behavior And Failure Handling

Neovim will continue to install missing plugins automatically. Plugin updates
will write their selected revisions to the tracked lockfile. A failed plugin
download or update will be reported by `lazy.nvim` and must not be treated as a
successful lockfile refresh.

## Verification

- Evaluate the Home Manager/Nix configuration without building it.
- Start Neovim headlessly with the repository configuration and confirm plugin
  setup completes without errors.
- Confirm `nvim-surround` is present, `vim-surround` is absent, and the tracked
  lockfile contains the current plugin set.
- Confirm the plugin exposes all default insert, normal, and visual mappings
  and representative default options without repository overrides.

## Out Of Scope

- Custom surround aliases, keymaps, or lazy-loading rules.
- Unrelated Neovim plugin upgrades or configuration refactoring.
