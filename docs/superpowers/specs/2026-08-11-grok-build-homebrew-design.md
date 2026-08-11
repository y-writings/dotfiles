# Grok Build Homebrew Design

## Goal

Declaratively manage xAI Grok Build while prioritizing timely stable releases.

## Package Choice

Use the official Homebrew cask `grok-build`. On 2026-08-11, the cask and xAI's
stable release are both version 1.0.0, while the repository-pinned
`nixpkgs-unstable` offers version 0.2.118.

The cask installs both the `grok` and `agent` binaries, together with their
shell completions. It is published in `homebrew/cask`, so no additional tap or
`nix-homebrew.trust` entry is needed.

## Change

Add `grok-build` to `homebrew.casks` in `nix/darwin/homebrew.nix`. Do not add a
Home Manager package for Grok Build because that would give two package
managers ownership of the same tool.

## Verification

- Format and evaluate the changed Nix configuration.
- Confirm `homebrew.casks` contains exactly one `grok-build` entry.
- Confirm Homebrew metadata identifies `grok-build` as a cask at the current
  stable version.
- After activation, confirm both `grok` and `agent` resolve from Homebrew.
