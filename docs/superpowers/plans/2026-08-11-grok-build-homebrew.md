# Grok Build Homebrew Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install the current stable xAI Grok Build release declaratively
through nix-darwin's Homebrew cask configuration.

**Architecture:** Add the official `grok-build` cask to the existing
`homebrew.casks` list. Keep ownership exclusively in Homebrew because its cask
tracks the current stable release and already supplies both binaries and shell
completions without an additional tap.

**Tech Stack:** Nix, nix-darwin, Homebrew Cask

---

## File Structure

- Modify: `nix/darwin/homebrew.nix` - owns declarative Homebrew packages.
- Create: `docs/superpowers/specs/2026-08-11-grok-build-homebrew-design.md` -
  records the package choice and intended behavior.
- Create: `docs/superpowers/plans/2026-08-11-grok-build-homebrew.md` - records
  implementation, verification, and delivery steps.

### Task 1: Add And Verify The Grok Build Cask

**Files:**

- Modify: `nix/darwin/homebrew.nix:42-85`
- Test: Direct Nix evaluation of `homebrew.casks`

- [ ] **Step 1: Confirm the cask is absent before editing**

Run:

```bash
! rg -q '^\s*"grok-build"$' nix/darwin/homebrew.nix
```

Expected: exit status 0 before the implementation is added.

- [ ] **Step 2: Add the cask in alphabetical order**

In `nix/darwin/homebrew.nix`, update the existing cask list:

```nix
      "ghostty@tip"
      "grok-build"
      "homerow"
```

Do not add a Home Manager package, tap, or `nix-homebrew.trust` entry.

- [ ] **Step 3: Check Nix formatting**

Run:

```bash
nix fmt -- --check nix/darwin/homebrew.nix
```

Expected: command exits successfully without changing the file.

- [ ] **Step 4: Evaluate the exact cask count**

Run:

```bash
nix eval --raw --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    module = import ./nix/darwin/homebrew.nix {
      lib = flake.inputs.nixpkgs.lib;
    };
    matches = builtins.filter
      (entry: builtins.isString entry && entry == "grok-build")
      module.homebrew.casks;
  in
  if builtins.length matches == 1
  then "ok"
  else throw "homebrew.casks must contain exactly one grok-build entry"'
```

Expected: command succeeds and prints `ok`.

- [ ] **Step 5: Confirm the current stable cask metadata**

Run:

```bash
HOMEBREW_NO_AUTO_UPDATE=1 brew info --cask --json=v2 grok-build \
  | jq -e '.casks | length == 1
    and .[0].token == "grok-build"
    and .[0].version == "1.0.0"'
```

Expected: output `true`; Homebrew identifies `grok-build` as the official cask
at the 2026-08-11 stable version.

- [ ] **Step 6: Verify both binaries after activation**

After applying the nix-darwin configuration, run:

```bash
brew_prefix="$(brew --prefix)"
for binary in grok agent; do
  resolved="$(command -v "$binary")"
  case "$resolved" in
    "$brew_prefix"/*) ;;
    *) exit 1 ;;
  esac
done
```

Expected: both commands resolve beneath the active Homebrew prefix.

- [ ] **Step 7: Inspect the focused implementation diff**

Run:

```bash
git diff --check
git diff -- nix/darwin/homebrew.nix
```

Expected: no whitespace errors and exactly one cask entry is added.

### Task 2: Commit And Prepare The Pull Request

**Files:**

- Stage: `nix/darwin/homebrew.nix`
- Stage: `docs/superpowers/specs/2026-08-11-grok-build-homebrew-design.md`
- Stage: `docs/superpowers/plans/2026-08-11-grok-build-homebrew.md`

- [ ] **Step 1: Review the complete commit payload**

Run:

```bash
git status --short
git diff --check
git diff
git log --oneline -10
```

Expected: review shows only the `grok-build` cask addition and these two docs,
for exactly three changed files, with no secrets or private machine details.

- [ ] **Step 2: Stage only the intended files and commit**

Run:

```bash
git add \
  nix/darwin/homebrew.nix \
  docs/superpowers/specs/2026-08-11-grok-build-homebrew-design.md \
  docs/superpowers/plans/2026-08-11-grok-build-homebrew.md
git commit -m "feat(nix): install Grok Build"
```

Expected: repository hooks pass and the local commit is created.

- [ ] **Step 3: Review the committed change before any publication**

Run:

```bash
git status --short --branch
git show --stat --oneline HEAD
git show --format=fuller --find-renames HEAD
```

Expected: the worktree is clean and the commit contains only the cask addition
and these two docs.

- [ ] **Step 4: Publish only when explicitly requested**

Do not run this step as part of the local commit task. Only after a later
request authorizes publication, re-run the privacy review and run:

```bash
git push -u origin feat/grok-build-homebrew
body=$'## Summary\n\n'
body+=$'- install the current stable Grok Build cask through nix-darwin\n'
body+=$'- document the Homebrew package choice and focused verification\n\n'
body+=$'## Verification\n\n'
body+=$'- `nix fmt -- --check nix/darwin/homebrew.nix`\n'
body+=$'- focused Nix evaluation confirms exactly one `grok-build` cask\n'
body+=$'- Homebrew metadata identifies the current stable cask'
gh pr create \
  --base main \
  --head feat/grok-build-homebrew \
  --title "feat(nix): install Grok Build" \
  --body "$body"
```

Expected: the branch is pushed and the pull request describes only this Grok
Build change without secrets or private machine details.
