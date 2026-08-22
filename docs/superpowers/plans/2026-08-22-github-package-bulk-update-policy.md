# GitHub Package Bulk Update Policy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep `agent-slack` pinned while the repository's shared updater
continues to update `codex-acp` and `difit` according to required per-package
metadata.

**Architecture:** Store a required `passthru.updateWithBulkUpdater` boolean on
every GitHub package derivation so package exposure and installation remain
unchanged. Validate the metadata in Nix checks, then have
`scripts/update-github-packages.sh` evaluate the complete flag map before it
skips disabled packages or invokes `nix-update` for enabled packages.

**Tech Stack:** Nix, Bash, jq, nix-update, ShellCheck, mise

---

## Task 1: Declare And Validate Package Update Metadata

**Files:**

- Modify: `nix/checks/default.nix:79-108`
- Modify: `nix/packages/github/agent-slack.nix:27-35`
- Modify: `nix/packages/github/codex-acp.nix:21-28`
- Modify: `nix/packages/github/difit.nix:52-59`

- [ ] **Step 1: Add a failing Nix policy check**

Extend the `github-package-management` check's `let` block immediately after
`githubPackageNames`:

```nix
      githubPackageBulkUpdateFlags = pkgs.lib.mapAttrs (
        _: package: package.passthru.updateWithBulkUpdater or null
      ) githubPackages;
```

Add these assertions after the existing non-empty package assertion:

```nix
    assert pkgs.lib.assertMsg (
      builtins.all builtins.isBool (builtins.attrValues githubPackageBulkUpdateFlags)
    ) "Every GitHub package must define boolean passthru.updateWithBulkUpdater metadata";
    assert pkgs.lib.assertMsg (
      !githubPackageBulkUpdateFlags.agent-slack
    ) "agent-slack must be excluded from bulk updates";
    assert pkgs.lib.assertMsg (
      githubPackageBulkUpdateFlags.codex-acp && githubPackageBulkUpdateFlags.difit
    ) "codex-acp and difit must be included in bulk updates";
```

- [ ] **Step 2: Run the focused check to verify it fails**

Run:

```bash
nix build .#checks.aarch64-darwin.github-package-management --no-link
```

Expected: FAIL with
`Every GitHub package must define boolean passthru.updateWithBulkUpdater metadata`.

- [ ] **Step 3: Add the required metadata to all package derivations**

Add this attribute before `meta` in `nix/packages/github/agent-slack.nix`:

```nix
  passthru.updateWithBulkUpdater = false;
```

Add this attribute before `meta` in both
`nix/packages/github/codex-acp.nix` and `nix/packages/github/difit.nix`:

```nix
  passthru.updateWithBulkUpdater = true;
```

- [ ] **Step 4: Format the changed Nix files**

Run:

```bash
nixfmt \
  nix/checks/default.nix \
  nix/packages/github/agent-slack.nix \
  nix/packages/github/codex-acp.nix \
  nix/packages/github/difit.nix
```

Expected: exit 0.

- [ ] **Step 5: Run the focused check to verify it passes**

Run:

```bash
nix build .#checks.aarch64-darwin.github-package-management --no-link
```

Expected: exit 0 and build the `github-package-management-check` derivation.

- [ ] **Step 6: Commit the metadata and policy check**

```bash
git add \
  nix/checks/default.nix \
  nix/packages/github/agent-slack.nix \
  nix/packages/github/codex-acp.nix \
  nix/packages/github/difit.nix
git commit -m "feat(nix): declare GitHub package update policy"
```

## Task 2: Filter The Shared Updater By Package Policy

**Files:**

- Modify: `nix/checks/default.nix:110-125`
- Modify: `scripts/update-github-packages.sh:14-25`

- [ ] **Step 1: Add a failing functional updater check**

Replace the `github-package-update-script` check with a check that retains
syntax and ShellCheck validation and runs the updater against fake Git, Nix,
`nix-update`, and nixfmt commands:

```nix
  github-package-update-script =
    let
      script = ../../scripts/update-github-packages.sh;
      fakeGit = pkgs.writeShellScriptBin "git" ''
        if [ "$*" = "rev-parse --show-toplevel" ]; then
          printf '%s\n' "$TEST_REPO_ROOT"
        else
          printf 'Unexpected git arguments: %s\n' "$*" >&2
          exit 1
        fi
      '';
      fakeNix = pkgs.writeShellScriptBin "nix" ''
        if [[ "$*" == *"builtins.currentSystem"* ]]; then
          printf '%s\n' 'aarch64-darwin'
        else
          printf '%s\n' "$TEST_PACKAGE_UPDATE_FLAGS"
        fi
      '';
      fakeNixUpdate = pkgs.writeShellScriptBin "nix-update" ''
        printf '%s\n' "$1" >> "$TEST_UPDATE_LOG"
      '';
      fakeNixfmt = pkgs.writeShellScriptBin "nixfmt" ''
        exit 0
      '';
    in
    pkgs.runCommand "github-package-update-script-check"
      {
        nativeBuildInputs = [
          pkgs.bash
          pkgs.jq
          pkgs.shellcheck
          fakeGit
          fakeNix
          fakeNixUpdate
          fakeNixfmt
        ];
      }
      ''
        bash -n ${script}
        shellcheck ${script}

        export TEST_REPO_ROOT="$TMPDIR/repo"
        export TEST_UPDATE_LOG="$TMPDIR/updates"
        mkdir -p "$TEST_REPO_ROOT"

        export TEST_PACKAGE_UPDATE_FLAGS='{"agent-slack":false,"codex-acp":true,"difit":true}'
        ${script} > "$TMPDIR/output"
        test "$(cat "$TEST_UPDATE_LOG")" = "$(printf 'codex-acp\ndifit')"
        grep -Fq 'Skipping agent-slack (bulk updates disabled)' "$TMPDIR/output"
        grep -Fq 'Updating codex-acp' "$TMPDIR/output"
        grep -Fq 'Updating difit' "$TMPDIR/output"

        : > "$TEST_UPDATE_LOG"
        export TEST_PACKAGE_UPDATE_FLAGS='{"agent-slack":false,"codex-acp":false,"difit":false}'
        ${script} > "$TMPDIR/all-disabled-output"
        test ! -s "$TEST_UPDATE_LOG"
        grep -Fq 'No GitHub packages enabled for bulk updates' "$TMPDIR/all-disabled-output"

        touch "$out"
      '';
```

- [ ] **Step 2: Run the updater check to verify it fails**

Run:

```bash
nix build .#checks.aarch64-darwin.github-package-update-script --no-link
```

Expected: FAIL because the current script passes boolean JSON values to
`nix-update` and does not print the skip message.

- [ ] **Step 3: Evaluate and enforce the package flag map before updating**

Replace `package_names` evaluation and the update loop in
`scripts/update-github-packages.sh` with:

```bash
package_update_flags=$(
  nix eval --json "path:.#packages.$system" --apply '
    packages:
    builtins.mapAttrs (
      name: package:
      let
        updateWithBulkUpdater =
          package.passthru.updateWithBulkUpdater
            or (throw "${name} must define passthru.updateWithBulkUpdater");
      in
      if builtins.isBool updateWithBulkUpdater then
        updateWithBulkUpdater
      else
        throw "${name}.passthru.updateWithBulkUpdater must be a boolean"
    ) packages
  '
)

if [[ "$(jq 'length' <<< "$package_update_flags")" -eq 0 ]]; then
  printf '%s\n' 'No GitHub packages found' >&2
  exit 1
fi

enabled_package_count=$(jq '[.[] | select(. == true)] | length' <<< "$package_update_flags")
if [[ "$enabled_package_count" -eq 0 ]]; then
  printf '%s\n' 'No GitHub packages enabled for bulk updates'
fi

while IFS=$'\t' read -r package update_with_bulk_updater; do
  if [[ "$update_with_bulk_updater" == "false" ]]; then
    printf 'Skipping %s (bulk updates disabled)\n' "$package"
    continue
  fi

  printf 'Updating %s\n' "$package"
  nix-update "$package" \
    --flake --system "$system" --use-github-releases --build --format
done < <(
  jq -r 'to_entries[] | [.key, .value] | @tsv' \
    <<< "$package_update_flags"
)
```

The `nix eval --json` call forces every mapped value before any `nix-update`
invocation, so missing or non-boolean metadata fails without a partial update.

- [ ] **Step 4: Run shell validation**

Run:

```bash
bash -n scripts/update-github-packages.sh
shellcheck scripts/update-github-packages.sh
```

Expected: both commands exit 0.

- [ ] **Step 5: Run the functional updater check to verify it passes**

Run:

```bash
nix build .#checks.aarch64-darwin.github-package-update-script --no-link
```

Expected: exit 0 and build the `github-package-update-script-check`
derivation. The fake update log contains only `codex-acp` and `difit`, and the
all-disabled run exits successfully without invoking `nix-update`.

- [ ] **Step 6: Commit the updater and functional check**

```bash
git add nix/checks/default.nix scripts/update-github-packages.sh
git commit -m "feat(nix): filter bulk GitHub package updates"
```

## Task 3: Verify The Complete Change

**Files:**

- Verify: `nix/checks/default.nix`
- Verify: `nix/packages/github/agent-slack.nix`
- Verify: `nix/packages/github/codex-acp.nix`
- Verify: `nix/packages/github/difit.nix`
- Verify: `scripts/update-github-packages.sh`

- [ ] **Step 1: Run both focused checks together**

Run:

```bash
nix build \
  .#checks.aarch64-darwin.github-package-management \
  .#checks.aarch64-darwin.github-package-update-script \
  --no-link
```

Expected: exit 0 and build both check derivations.

- [ ] **Step 2: Run the complete evaluation-only flake check**

Run:

```bash
nix flake check --no-build
```

Expected: exit 0 with every flake output evaluated successfully.

- [ ] **Step 3: Re-run direct static validation**

Run:

```bash
nixfmt --check \
  nix/checks/default.nix \
  nix/packages/github/agent-slack.nix \
  nix/packages/github/codex-acp.nix \
  nix/packages/github/difit.nix
bash -n scripts/update-github-packages.sh
shellcheck scripts/update-github-packages.sh
git diff --check
```

Expected: every command exits 0 with no formatting, shell, or whitespace
errors.

- [ ] **Step 4: Inspect the final branch diff**

Run:

```bash
git status --short
git diff origin/main...HEAD
```

Expected: the branch diff contains only the design, plan, package metadata,
Nix checks, and updater changes. Pre-existing unrelated editor settings remain
uncommitted and are not included in the branch diff.
