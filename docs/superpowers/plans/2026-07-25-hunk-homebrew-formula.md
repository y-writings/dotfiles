# Hunk Homebrew Formula Implementation Plan

> **For agentic workers:** Use the subagent-driven-development or
> executing-plans skill to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make nix-darwin install Hunk from the current Homebrew Core formula token.

**Architecture:** Keep Hunk in the existing `homebrew.brews` list because it
is a formula. Replace the obsolete qualified token with `hunk`; do not add a
tap, trust rule, or runtime configuration change.

**Tech Stack:** Nix, nix-darwin, Homebrew, Nix flake checks.

---

## Task 1: Update the Homebrew formula token

**Files:**

- Modify: `nix/darwin/homebrew.nix:32-36`

- [ ] **Step 1: Replace the obsolete formula token**

Change the `homebrew.brews` entry from:

```nix
"homebrew/core/hunk"
```

to:

```nix
"hunk"
```

Leave `homebrew.taps`, `nix-homebrew.trust.formulae`, and the LazyGit pager
configuration unchanged.

## Task 2: Verify the configuration

**Files:**

- Verify: `nix/darwin/homebrew.nix`
- Verify: `flake.nix`

- [ ] **Step 1: Check Nix formatting**

Run:

```bash
nix fmt -- --check nix/darwin/homebrew.nix
```

Expected: the command exits successfully without formatting changes.

- [ ] **Step 2: Evaluate the Darwin module**

Run:

```bash
nix eval .#darwinModules.default
```

Expected: evaluation succeeds.

- [ ] **Step 3: Run the flake checks**

Run:

```bash
nix flake check --no-build
```

Expected: all checks complete successfully.

- [ ] **Step 4: Confirm the final Homebrew token set**

Run:

```bash
rg -n 'homebrew/core/hunk|"hunk"' nix/darwin/homebrew.nix nix/home
```

Expected: `homebrew/core/hunk` has no matches, and `"hunk"` appears in
`nix/darwin/homebrew.nix` under `homebrew.brews`.
