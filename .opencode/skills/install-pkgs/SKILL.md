---
name: install-pkgs
description: Add packages to this dotfiles repository's Nix, nix-darwin, Home Manager, or Homebrew configuration. Use this skill whenever a user asks to install, add, move, or audit packages in this repo, especially when choosing between nix/home packages and nix/darwin/homebrew.nix or when a Homebrew tap, cask, formula, or Brewfile failure is involved.
compatibility: opencode
metadata:
  repository: y-writings/dotfiles
  domain: nix-darwin-home-manager-homebrew
---

# Install Packages Skill

Use this skill to add packages to this repository without guessing the package manager, file, or Homebrew token shape. The repo is a macOS dotfiles flake using Nix, nix-darwin, Home Manager, and nix-homebrew, so package placement affects rebuild behavior and duplicate installs.

## Core workflow

1. **Gather context before editing.** Inspect the repo structure and the relevant Nix modules. In this repo, the usual files are:
   - `flake.nix` for the flake stack and public outputs
   - `nix/darwin/homebrew.nix` for Homebrew taps, formulae, casks, and MAS apps
   - `nix/home/packages.nix`, `nix/home/packages-stable.nix`, `nix/home/packages-unstable.nix`, and `nix/home/packages-github.nix` for Home Manager user packages
   - `nix/home/programs/*/default.nix` for package-specific Home Manager program modules
2. **Check duplicates and conflicts.** Search for the requested package name, binary name, tap name, cask token, formula token, and obvious aliases. If moving from Nix to Homebrew or vice versa, remove the old install only when the user requested that direction or when duplicate installation would clearly break the rebuild.
3. **Identify the package shape.** Confirm whether it is a CLI, GUI app, daemon/service, language runtime, development library, shell integration, or app-store package. Also confirm platform support, because this repository targets macOS `aarch64-darwin`.
4. **Choose the management location.** Prefer the smallest configuration surface that matches how the package is distributed and used.
5. **Implement surgically.** Match the existing list style, grouping, and ordering. Avoid broad refactors during package additions.
6. **Verify.** Run Nix formatting, diagnostics, relevant Nix evals, duplicate searches, and Homebrew token checks when Homebrew is involved.

## Placement decision guide

- Use `nix/home/packages-*.nix` for normal CLI tools and libraries available in nixpkgs, especially when a portable Nix package works well.
- Use `nix/home/programs/<name>/default.nix` when Home Manager has a meaningful `programs.<name>.enable` module or when dotfile/config generation is part of the install.
- Use `nix/darwin/homebrew.nix` for macOS GUI apps, casks, Mac App Store apps, vendor-distributed Homebrew packages, packages missing/broken in nixpkgs, or when the user explicitly says to install on the brew side.
- Use `homebrew.brews` only for Homebrew **formulae**.
- Use `homebrew.casks` only for Homebrew **casks**.
- Use `homebrew.taps` whenever the formula or cask is not in Homebrew core/cask and requires a third-party tap.

Respect explicit user intent. If the user says `brew側で`, choose `nix/darwin/homebrew.nix` unless there is concrete evidence that Homebrew cannot install the package.

## Homebrew tap/cask/formula verification

This section exists because a real failure happened: a package looked like `brew install entire`, but the tap actually contained `Casks/entire.rb` and no `Formula/entire.rb`. `brew bundle` then tried to fetch `entire` as a formula and failed. Prevent that class of mistake every time.

When a package uses Homebrew, do not trust a single README snippet. Compare the install docs with the actual tap contents or Homebrew metadata:

1. **Determine the tap.** `brew tap owner/tap` usually maps to `https://github.com/owner/homebrew-tap`.
2. **Check actual files.** Look for:
   - `Formula/<token>.rb` or `Formula/<token>@<channel>.rb` for formulae
   - `Casks/<token>.rb` or `Casks/<token>@<channel>.rb` for casks
3. **Classify the package from the files, not the prose.** If only `Casks/<token>.rb` exists, it belongs in `homebrew.casks`; if only `Formula/<token>.rb` exists, it belongs in `homebrew.brews`.
4. **Add required taps.** Add `"owner/tap"` to `homebrew.taps` when using a third-party tap.
5. **Prefer tap-qualified tokens for third-party casks/formulae.** This avoids ambiguous Brewfile resolution and protects against names that Homebrew interprets as a formula:
   - Formula: `homebrew.brews = [ "owner/tap/token" ];`
   - Cask: `homebrew.casks = [ "owner/tap/token" ];`
6. **Validate the generated intent.** Directly evaluate the Nix list or Brewfile if possible and confirm that the package appears in the intended section: cask entries must come from `homebrew.casks`, not `homebrew.brews`.
7. **Treat docs drift as a finding.** If README says `brew install owner/tap/token` but the tap only has `Casks/token.rb`, record that the correct install shape is `brew install --cask owner/tap/token` and encode it as a cask.

### Homebrew failure diagnosis hints

- `No available formula with the name "X"` often means `X` was placed under `homebrew.brews`, or Homebrew resolved an ambiguous token as a formula.
- If `brew info --cask owner/tap/token` says the tap is required, that does not disprove the token; it means the rebuild must include `homebrew.taps = [ "owner/tap" ];` before the cask line.
- For nix-darwin, strings in `homebrew.casks` render as Brewfile `cask "..."`; strings in `homebrew.brews` render as `brew "..."`.

## Required investigation report

Before or alongside implementation, synthesize findings in this shape:

1. **調査結果サマリー**: repo stack, existing package locations, duplicate/conflict status, package type, platform support.
2. **推奨追加方法**: target file, exact list/option, and why it fits this repo.
3. **実装例 / 実装内容**: Nix snippet or files changed.
4. **利用者への確認事項**: only include questions when a decision is genuinely impossible from repo/docs evidence.

## Verification checklist

After edits, run as many of these as apply:

- `lsp_diagnostics` for modified Nix files
- `nixfmt --check <modified files>`
- `nix eval .#darwinModules.default`
- `nix eval .#homeModules.default` when Home Manager package lists changed
- `nix flake check --no-build`
- targeted `nix eval --expr ...` or equivalent to confirm the changed `homebrew.taps`, `homebrew.brews`, or `homebrew.casks` values
- a duplicate search for the package/token after editing
- Homebrew metadata checks such as `brew info --formula ...` or `brew info --cask ...` when available and safe

Report both successful checks and any warnings that appear to be pre-existing.

## Example: tapped cask

If the package is `owner/tap` + `Casks/tool.rb`, prefer:

```nix
homebrew = {
  taps = [
    "owner/tap"
  ];

  casks = [
    "owner/tap/tool"
  ];
};
```

Do not put this in `brews` unless `Formula/tool.rb` exists.
