# Git Pull Rebase Design

## Goal

Configure Git pulls to rebase by default, equivalent to running
`git config --global pull.rebase true`.

## Configuration

Add `pull.rebase = true` to the existing Home Manager
`programs.git.settings` attribute set. This follows the repository's canonical
Git configuration path and lets Home Manager render the value into the managed
global Git configuration.

Do not use `extraConfig` or manage `.gitconfig` directly because both would
duplicate the existing settings mechanism.

## Behavior

After the Home Manager configuration is activated, `git pull` rebases local
commits onto the fetched branch unless a repository-specific setting overrides
the global value. Other pull and rebase settings remain unchanged.

## Verification

- Assert that the evaluated Home Manager configuration contains
  `programs.git.settings.pull.rebase = true`.
- Run the repository's Nix flake checks.
- Format the changed Nix files and confirm the working diff contains only the
  intended Git setting, assertion, and supporting documentation.
