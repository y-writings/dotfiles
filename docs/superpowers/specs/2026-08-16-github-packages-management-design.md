# GitHub Packages Management Design

## Goal

Declaratively install and update CLI packages that this repository fetches
directly from GitHub without adding per-package wiring to `flake.nix`, Home
Manager, or mise as the collection grows.

## Scope

The initial package set contains:

- `codex-acp` from `agentclientprotocol/codex-acp`
- `difit` from `yoshiko-pg/difit`

All packages registered in this set are installed and updated automatically.
There is no separate enabled-package list.

`driftline` remains outside this set because upstream already provides a flake
package. Its revision and hash continue to be managed through the `driftline`
flake input and `flake.lock`.

## Package Layout

Store directly managed GitHub packages under a dedicated package set:

```text
nix/packages/github/
├── default.nix
├── codex-acp.nix
└── difit.nix
```

`default.nix` is the only package registry. It returns an attribute set whose
keys are package names and whose values are derivations created with
`pkgs.callPackage`.

Keep this registry explicit rather than discovering files with
`builtins.readDir`. Explicit registration prevents helper files from becoming
packages accidentally and makes the complete package set readable in one
place.

## Package Implementations

Use the smallest reproducible implementation supported by each upstream:

- Build `codex-acp` from its tagged GitHub source with `buildNpmPackage`, its
  committed `package-lock.json`, a source hash, and `npmDepsHash`.
- Build `difit` from its tagged GitHub source with the Nix pnpm hooks, its
  committed `pnpm-lock.yaml`, a source hash, and the fixed pnpm dependency
  output.

Each package declares its GitHub homepage and source owner/repository so its
origin remains visible in both the directory layout and the derivation.

Dependency ranges such as `^` are resolved only in upstream lock files. Nix
builds consume the exact locked dependency graph and fixed hashes; they do not
resolve newer semver-compatible releases during a rebuild.

## Flake Integration

Import the package set once as `githubPackages` and assign the complete set to
the standard package output:

```nix
packages.${hostSystem} = githubPackages;
```

This creates `.#codex-acp` and `.#difit` for standard Nix tooling without
maintaining individual output declarations. Adding a package requires only its
package file and one entry in
`nix/packages/github/default.nix`.

## Home Manager Integration

Home Manager imports the same package set and appends
`builtins.attrValues githubPackages` to `home.packages`. Every registered
GitHub package is therefore installed automatically.

Rename the existing `nix/home/packages-github.nix` file to
`nix/home/packages-flake-inputs.nix`. Remove its `difit` wrapper, move `difit`
into `nix/packages/github`, and leave `driftline` as the flake-provided Home
Manager package in the renamed file.

## Update Flow

Keep the two ownership models separate inside one mise update command:

1. `nix flake update` updates `driftline`, nixpkgs, Home Manager, and the other
   flake inputs.
2. `scripts/update-github-packages.sh` evaluates the names under
   `packages.aarch64-darwin` and runs `nix-update` for each directly managed
   GitHub package.
3. Each `nix-update` invocation discovers the latest stable GitHub release,
   updates the version and fixed hashes, formats the package file, and builds
   the resulting derivation.
4. `nix flake check --no-build` verifies the final combined configuration.

Install `nix-update` as a normal nixpkgs package, not as a member of
`githubPackages`, so it is not included in the dynamically enumerated update
targets.

The mise task calls `scripts/update-github-packages.sh` rather than embedding
the enumeration loop in TOML. The script captures the package list before
updating and processes it sequentially with fail-fast shell settings.

## Failure Behavior

Stop on the first failed source update, dependency hash update, package build,
or flake check. Preserve successful earlier edits in the worktree for review;
do not automatically revert them. Never run the GitHub package updater with
`sudo`, because it writes tracked Nix files.

An unsupported package update is a hard failure. New package definitions must
expose the conventional `pname`, `version`, and source metadata expected by
`nix-update`, or provide a package-specific update script when the conventional
path cannot work.

## Security Properties

- Rebuilds do not use `npx` or resolve `latest` at runtime.
- GitHub source archives and Release assets are protected by Nix hashes.
- npm and pnpm dependency graphs are protected by committed lock files and
  fixed dependency hashes.
- Authentication and application state remain in user-owned configuration and
  are never embedded in derivations or the Nix store.
- The design provides immutability and reproducibility, not proof that newly
  accepted upstream bytes are benign. Updates remain reviewable Git diffs.

## Verification

- Format every changed Nix file.
- Build `.#codex-acp` and `.#difit`.
- Confirm each executable reports the pinned version from the built output.
- Evaluate the GitHub package attribute names and confirm Home Manager installs
  the same set exactly once.
- Confirm `driftline` remains sourced only from its flake input.
- Run the GitHub package update script with all packages already current and
  confirm it exits successfully without changing files.
- Run `nix flake check --no-build`.
