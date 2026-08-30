# GitHub Packages Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install and update all directly managed GitHub CLI packages through
one explicit package registry without per-package flake, Home Manager, or mise
wiring.

**Architecture:** Define `codex-acp` and `difit` as focused Nix derivations
under `nix/packages/github`, then expose the whole attribute set as the flake
package output and install all of its values through Home Manager. A single
fail-fast script enumerates those flake package names and runs `nix-update`;
`driftline` remains a flake input updated by `nix flake update`.

**Tech Stack:** Nix, nix-darwin, Home Manager, `buildNpmPackage`,
`fetchPnpmDeps`, `nix-update`, mise, Bash

---

## File Structure

- Create: `nix/packages/github/default.nix` - explicit registry of all directly
  managed GitHub packages.
- Create: `nix/packages/github/codex-acp.nix` - builds the ACP adapter from its
  npm lock.
- Create: `nix/packages/github/difit.nix` - builds the CLI from its pnpm lock.
- Modify: `flake.nix` - publishes the complete GitHub package set once.
- Modify: `nix/home/packages.nix` - installs every registered GitHub package.
- Rename: `nix/home/packages-github.nix` to
  `nix/home/packages-flake-inputs.nix` - retains only packages supplied by flake
  inputs.
- Modify: `nix/home/packages-unstable.nix` - installs `nix-update` as a
  maintenance tool.
- Modify: `nix/checks/default.nix` - verifies package-set membership, Home
  Manager installation, driftline ownership, and updater script syntax.
- Create: `scripts/update-github-packages.sh` - dynamically updates every
  registered GitHub package.
- Modify: `.mise/config.toml` - composes flake and GitHub package updates.
- Modify: `.agents/skills/install-pkgs/SKILL.md` - documents the package
  ownership locations introduced by this change.
- Existing: `docs/superpowers/specs/2026-08-16-github-packages-management-design.md`
  - records the approved architecture.

### Task 1: Add The Codex ACP Package

**Files:**

- Create: `nix/packages/github/codex-acp.nix`
- Test: direct Nix build and version invocation

- [ ] **Step 1: Confirm no current local package exists**

Run:

```bash
test ! -e nix/packages/github/codex-acp.nix
```

Expected: exit status 0 before implementation.

- [ ] **Step 2: Create the locked npm derivation**

Create `nix/packages/github/codex-acp.nix`:

```nix
{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:

buildNpmPackage (finalAttrs: {
  pname = "codex-acp";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9oUtDBE1HINQaJhk4Le5GWN3YODNwDpRaVZlnDV9a5c=";
  };

  npmDepsHash = "sha256-tHnOMBXerUKBqTQM+jbXT3F9wgodvP6xdWJd7XNwhxE=";
  npmBuildScript = "build";

  meta = {
    description = "ACP adapter for Codex CLI";
    homepage = "https://github.com/agentclientprotocol/codex-acp";
    changelog = "https://github.com/agentclientprotocol/codex-acp/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "codex-acp";
    platforms = [ "aarch64-darwin" ];
  };
})
```

- [ ] **Step 3: Format and build the package directly**

Run:

```bash
nix fmt -- --check nix/packages/github/codex-acp.nix
out="$(nix build --impure --no-link --print-out-paths --expr '
  let
    flake = builtins.getFlake (toString ./.);
    pkgs = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin;
  in
  pkgs.callPackage ./nix/packages/github/codex-acp.nix { }
')"
"$out/bin/codex-acp" --version
```

Expected: the build succeeds and prints
`@agentclientprotocol/codex-acp 1.4.0`.

### Task 2: Replace The Difit Runtime Download

**Files:**

- Create: `nix/packages/github/difit.nix`
- Later remove: the `difitFromGitHub` wrapper from
  `nix/home/packages-github.nix`
- Test: direct Nix build and version invocation

- [ ] **Step 1: Record the current runtime-download behavior**

Run:

```bash
rg -n 'npx --yes difit' nix/home/packages-github.nix
```

Expected: one match identifies the behavior that this package replaces.

- [ ] **Step 2: Create the locked pnpm derivation**

Create `nix/packages/github/difit.nix`:

<!-- markdownlint-disable MD013 -->

```nix
{
  buildNpmPackage,
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  pnpm_11,
  pnpmConfigHook,
}:

let
  pnpm = pnpm_11;
in
buildNpmPackage (finalAttrs: {
  pname = "difit";
  version = "5.0.11";

  src = fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    tag = "v${finalAttrs.version}";
    hash = "sha256-0qef7IhDOEPwLXhXe+vU52c505sH03xRbjUQUqgmyQ4=";
  };

  npmDeps = null;
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-PLV82tBaOX7hDxRcV2owulK4EslaEcJGM1N1uuEQei8=";
  };

  nativeBuildInputs = [ pnpm ];
  npmConfigHook = pnpmConfigHook;
  npmBuildScript = "build";

  # npm pack otherwise runs upstream's prepare hook, which invokes lefthook.
  npmPackFlags = [ "--ignore-scripts" ];

  # npm cannot safely prune a pnpm workspace after the frozen install.
  dontNpmPrune = true;

  # Replace build-time dev dependencies with the exact production graph before npmInstallHook copies the package.
  postBuild = ''
    rm -rf node_modules packages/vscode/node_modules
    pnpm install --prod --offline --frozen-lockfile --ignore-scripts
  '';

  postInstall = ''
    rm "$out/lib/node_modules/difit/node_modules/.pnpm/node_modules/difit-vscode"
  '';

  meta = {
    description = "GitHub-like local diff viewer";
    homepage = "https://github.com/yoshiko-pg/difit";
    changelog = "https://github.com/yoshiko-pg/difit/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "difit";
    platforms = [ "aarch64-darwin" ];
  };
})
```

<!-- markdownlint-enable MD013 -->

- [ ] **Step 3: Format and build with a bounded execution budget**

Run the following with a 10-minute tool timeout. The production dependency
reinstall has been verified to complete offline from the fixed pnpm dependency
output:

```bash
nix fmt -- --check nix/packages/github/difit.nix
out="$(nix build --impure --no-link --print-out-paths --expr '
  let
    flake = builtins.getFlake (toString ./.);
    pkgs = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin;
  in
  pkgs.callPackage ./nix/packages/github/difit.nix { }
')"
"$out/bin/difit" --version
```

Expected: no registry access occurs during the sandboxed build. The build
replaces the development tree with the exact production graph using
`pnpm install --prod --offline --frozen-lockfile --ignore-scripts`, removes
only the dangling `difit-vscode` workspace symlink from the copied output, and
`difit --version` prints `5.0.11`.

- [ ] **Step 4: Fail rather than reintroduce runtime resolution**

If Step 3 fails, keep the failing package isolated and diagnose its install
phase. Do not restore `npx`, add `latest`, enable build-time network access, or
replace the lock with a generated unlocked install.

### Task 3: Register And Publish The Package Set

**Files:**

- Create: `nix/packages/github/default.nix`
- Modify: `flake.nix:47-90,134-140`
- Test: flake package-name evaluation

- [ ] **Step 1: Create the sole explicit package registry**

Create `nix/packages/github/default.nix`:

```nix
{ pkgs }:
{
  codex-acp = pkgs.callPackage ./codex-acp.nix { };
  difit = pkgs.callPackage ./difit.nix { };
}
```

- [ ] **Step 2: Import the registry once in the flake**

In the top-level `let` in `flake.nix`, add:

```nix
      pkgs = nixpkgs.legacyPackages.${hostSystem};
      githubPackages = import ./nix/packages/github { inherit pkgs; };
```

Reuse this `pkgs` binding in `formatter.${hostSystem}` by removing the
formatter's nested `let pkgs = ...; in`.

- [ ] **Step 3: Publish the complete set and pass it to checks**

Add this output beside the module outputs:

```nix
      packages.${hostSystem} = githubPackages;
```

Pass the set into the existing checks import:

```nix
      checks.${hostSystem} = import ./nix/checks {
        inherit
          githubPackages
          inputs
          hostSystem
          homeModule
          mkDarwinSystem
          ;
      };
```

- [ ] **Step 4: Verify automatic output generation**

Run:

```bash
nix fmt -- --check flake.nix nix/packages/github/default.nix
nix eval --json path:.#packages.aarch64-darwin --apply builtins.attrNames
```

Expected:

```json
["codex-acp", "difit"]
```

### Task 4: Install The Entire Set Through Home Manager

**Files:**

- Rename: `nix/home/packages-github.nix` to
  `nix/home/packages-flake-inputs.nix`
- Modify: `nix/home/packages.nix`
- Modify: `nix/home/packages-unstable.nix:54-58`
- Test: Home Manager module evaluation

- [ ] **Step 1: Replace the mixed GitHub file with a flake-input-only file**

Rename the file and replace its contents with:

```nix
{ inputs, pkgs }:
[
  inputs.driftline.packages.${pkgs.system}.driftline
]
```

The old `difitFromGitHub` and `npx --yes difit` wrapper must be removed rather
than retained as a fallback.

- [ ] **Step 2: Import and install all registered packages**

Replace `nix/home/packages.nix` with:

```nix
{ pkgs, inputs, ... }:
let
  stablePkgs = inputs.nixpkgs-stable.legacyPackages.${pkgs.system};
  stablePackages = import ./packages-stable.nix { inherit stablePkgs; };
  unstablePackages = import ./packages-unstable.nix { inherit pkgs; };
  githubPackages = import ../packages/github { inherit pkgs; };
  flakeInputPackages = import ./packages-flake-inputs.nix {
    inherit pkgs inputs;
  };
in
{
  home.packages =
    unstablePackages
    ++ stablePackages
    ++ builtins.attrValues githubPackages
    ++ flakeInputPackages;
}
```

- [ ] **Step 3: Install the updater from nixpkgs**

Add `nix-update` to the tools section of
`nix/home/packages-unstable.nix`. Keep it near the other Nix maintenance tools:

```nix
  neovim
  nil
  nix-update
  nixfmt
  opencode
```

- [ ] **Step 4: Verify the Home Manager module evaluates**

Run:

```bash
nix fmt -- --check \
  nix/home/packages.nix \
  nix/home/packages-flake-inputs.nix \
  nix/home/packages-unstable.nix
nix eval path:.#homeModules.default
! rg -n 'npx --yes difit|difitFromGitHub' nix
```

Expected: every command succeeds and the removed runtime wrapper has no
matches.

### Task 5: Add Package Ownership Checks

**Files:**

- Modify: `nix/checks/default.nix:1-74,75-103`
- Test: focused flake check build

- [ ] **Step 1: Accept the package set in the check module**

Add `githubPackages` to the argument set at the top of
`nix/checks/default.nix`:

```nix
{
  inputs,
  hostSystem,
  homeModule,
  mkDarwinSystem,
  githubPackages,
}:
```

- [ ] **Step 2: Add exact membership and ownership assertions**

Add this check near `exported-home-base`:

```nix
  github-package-management =
    let
      configuration = homeConfiguration [ ];
      homePackagePaths = map (package: package.outPath) configuration.config.home.packages;
      githubPackageNames = builtins.attrNames githubPackages;
      githubPackagePaths = map (name: githubPackages.${name}.outPath) githubPackageNames;
      driftline = inputs.driftline.packages.${hostSystem}.driftline;
      count = needle: builtins.length (builtins.filter (path: path == needle) homePackagePaths);
    in
    assert githubPackageNames != [ ];
    assert builtins.all (path: count path == 1) githubPackagePaths;
    assert !(builtins.hasAttr "driftline" githubPackages);
    assert count driftline.outPath == 1;
    pkgs.runCommand "github-package-management-check" { } ''
      touch "$out"
    '';
```

- [ ] **Step 3: Build the focused check**

Run:

```bash
nix fmt -- --check nix/checks/default.nix
nix build path:.#checks.aarch64-darwin.github-package-management
```

Expected: the check builds successfully, proving that every registered package
and `driftline` are installed exactly once under their intended ownership
models. Adding a future registry entry must not require editing this check.

### Task 6: Add The Dynamic GitHub Package Updater

**Files:**

- Create: `scripts/update-github-packages.sh`
- Modify: `nix/checks/default.nix`
- Test: Bash syntax, ShellCheck, package enumeration, and no-op updates

- [ ] **Step 1: Create the fail-fast updater**

Create `scripts/update-github-packages.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

for command in git jq nix nix-update nixfmt; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'error: required command not found: %s\n' "$command" >&2
    exit 1
  fi
done

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

system="$(nix eval --impure --raw --expr builtins.currentSystem)"
package_names="$(
  nix eval --json "path:.#packages.$system" --apply builtins.attrNames |
    jq -r '.[]'
)"

if [[ -z "$package_names" ]]; then
  printf 'error: no GitHub packages found for %s\n' "$system" >&2
  exit 1
fi

while IFS= read -r package; do
  printf 'Updating %s\n' "$package"
  nix-update "$package" \
    --flake \
    --system "$system" \
    --use-github-releases \
    --build \
    --format
done <<< "$package_names"
```

Make it executable:

```bash
chmod 755 scripts/update-github-packages.sh
```

- [ ] **Step 2: Add a static script check**

Add this check to `nix/checks/default.nix`:

```nix
  github-package-update-script = pkgs.runCommand
    "github-package-update-script-check"
    {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.shellcheck
    ];
    }
    ''
      bash -n ${../../scripts/update-github-packages.sh}
      shellcheck ${../../scripts/update-github-packages.sh}
      touch "$out"
    '';
```

- [ ] **Step 3: Verify script syntax and dynamic enumeration**

Run:

```bash
bash -n scripts/update-github-packages.sh
shellcheck scripts/update-github-packages.sh
nix eval --json path:.#packages.aarch64-darwin --apply builtins.attrNames
nix build path:.#checks.aarch64-darwin.github-package-update-script
```

Expected: syntax and ShellCheck pass, the same two package names are printed,
and the focused check builds.

- [ ] **Step 4: Verify each updater after the new files are tracked by Git**

Run:

```bash
nix_update="$(
  nix build --impure --no-link --print-out-paths --expr '
    let
      flake = builtins.getFlake (toString ./.);
    in
    flake.inputs.nixpkgs.legacyPackages.aarch64-darwin.nix-update
  '
)"
PATH="$nix_update/bin:$PATH" scripts/update-github-packages.sh
```

Expected: each current package reports that it is already current, both build
validations pass, and no package file changes. The updater must not run
with `sudo`.

### Task 7: Compose The Mise Update Workflow

**Files:**

- Modify: `.mise/config.toml:1-3`
- Test: mise task listing and TOML diagnostics

- [ ] **Step 1: Expand the update task sequentially**

Replace the current task with:

```toml
[tasks.update]
description = "Update flake inputs and GitHub packages"
run = [
  "sudo nix flake update",
  "./scripts/update-github-packages.sh",
  "nix flake check --no-build",
]
```

This keeps `driftline` in the first step and the two directly managed GitHub
packages in the second step.

- [ ] **Step 2: Verify mise parses the composed task**

Run:

```bash
tombi lint .mise/config.toml
mise tasks | rg '^update\s+Update flake inputs and GitHub packages$'
```

Expected: TOML lint passes and mise lists the updated task description.

### Task 8: Run End-To-End Verification

**Files:**

- Verify: all implementation files and approved documentation
- Verify: `.agents/skills/install-pkgs/SKILL.md` package-location correction
- Preserve: the pre-existing modification to `nix/home/files/zed/settings.json`

- [ ] **Step 1: Format and inspect the complete change**

Run:

```bash
nix fmt -- --check \
  flake.nix \
  nix/checks/default.nix \
  nix/home/packages.nix \
  nix/home/packages-flake-inputs.nix \
  nix/home/packages-unstable.nix \
  nix/packages/github/default.nix \
  nix/packages/github/codex-acp.nix \
  nix/packages/github/difit.nix
markdownlint-cli2 \
  docs/superpowers/specs/2026-08-16-github-packages-management-design.md \
  docs/superpowers/plans/2026-08-16-github-packages-management.md
git diff --check
```

Expected: all Nix format, documentation Markdown, and whitespace checks pass.
The modified install-pkgs skill is reviewed in the scoped diff; pre-existing
MD013 violations in its unrelated prose are not reformatted as part of this
task.

- [ ] **Step 2: Build all package outputs**

Run with a 180-second command timeout:

```bash
nix build --no-link \
  path:.#codex-acp \
  path:.#difit
"$(nix path-info path:.#codex-acp)/bin/codex-acp" --version
"$(nix path-info path:.#difit)/bin/difit" --version
```

Expected: both outputs build successfully without runtime package resolution
and report versions `1.4.0` and `5.0.11`, respectively.

- [ ] **Step 3: Run flake checks**

Run `nix flake check` with a 120-second command timeout, then build both focused
checks together with a separate 120-second command timeout:

```bash
nix flake check path:. --no-build
nix build --no-link \
  path:.#checks.aarch64-darwin.github-package-management \
  path:.#checks.aarch64-darwin.github-package-update-script
```

Expected: evaluation succeeds and both focused checks build.

- [ ] **Step 4: Inspect package ownership and unrelated changes**

Run:

```bash
! rg -n 'npx --yes difit|difitFromGitHub' nix
rg -n 'driftline' \
  flake.nix \
  nix/checks/default.nix \
  nix/home/packages-flake-inputs.nix
git status --short
git diff -- \
  .agents/skills/install-pkgs/SKILL.md \
  flake.nix \
  nix/checks/default.nix \
  nix/home/packages.nix \
  nix/home/packages-github.nix \
  nix/home/packages-flake-inputs.nix \
  nix/home/packages-unstable.nix \
  nix/packages/github \
  scripts/update-github-packages.sh \
  .mise/config.toml \
  docs/superpowers/specs/2026-08-16-github-packages-management-design.md \
  docs/superpowers/plans/2026-08-16-github-packages-management.md
```

Expected: the diff contains only the approved package-management changes,
quality-review skill documentation correction, and approved documentation.
There is no runtime `npx` difit wrapper, and `driftline` remains owned by its
flake input. Do not modify, stage, or revert the existing
`nix/home/files/zed/settings.json` change.

- [ ] **Step 5: Leave publication actions to an explicit later request**

Do not commit, push, or create a pull request unless the user explicitly asks
for those actions after reviewing the verified implementation.
