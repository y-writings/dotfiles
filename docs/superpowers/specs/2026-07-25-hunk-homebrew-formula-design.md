# Hunk Homebrew Formula Design

## Scope

Make the declarative Homebrew configuration install Hunk using the current
Homebrew Core formula token.

## Findings

- `nix/darwin/homebrew.nix` currently lists `homebrew/core/hunk` under
  `homebrew.brews`.
- Homebrew Core currently exposes the formula as `hunk`, with the documented
  command `brew install hunk`.
- Hunk is a formula, not a cask, and does not require a third-party tap.
- Hunk is already referenced by the LazyGit pager configuration, so no
  runtime configuration change is needed.

## Design

Replace only the Homebrew formula entry `homebrew/core/hunk` with `hunk`.
Do not add a tap or trust entry, and do not change the LazyGit configuration.

## Verification

- Format the modified Nix file.
- Evaluate the Darwin module and confirm the formula list contains `hunk`.
- Run `nix flake check --no-build`.
- Search the repository to confirm the obsolete token is gone and the current
  token appears only in the intended configuration and related references.
