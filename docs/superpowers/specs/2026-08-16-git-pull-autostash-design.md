# Git Pull Auto-Stash Design

## Goal

Configure Git to stash local changes automatically before a rebase-based pull,
equivalent to running `git config --global pull.autoStash true`.

## Configuration

Add `pull.autoStash = true` to the existing Home Manager
`programs.git.settings` attribute set. This keeps the setting in the
repository's canonical global Git configuration and complements the existing
`pull.rebase = true` setting.

Do not use `extraConfig` or manage `.gitconfig` directly because either option
would duplicate the existing settings mechanism.

## Behavior

After Home Manager activates the configuration, `git pull` temporarily stashes
local changes before rebasing and reapplies them afterward. Repository-specific
Git configuration can still override the global value.

## Verification

- Assert that the evaluated Home Manager configuration contains
  `programs.git.settings.pull.autoStash = true`.
- Confirm the assertion fails before adding the setting.
- Format the changed Nix files and run the repository's Nix flake checks.
