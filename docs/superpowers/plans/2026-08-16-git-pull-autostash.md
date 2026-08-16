# Git Pull Auto-Stash Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Manage the global Git `pull.autoStash` setting as `true` through Home
Manager.

**Architecture:** Extend the existing `programs.git.settings` attribute set
rather than introducing another Git configuration path. Protect the generated
value with an assertion in the existing Git integration check.

**Tech Stack:** Nix, Home Manager, Git

---

## File Structure

- Modify: `nix/home/programs/git/default.nix` - owns global Git settings.
- Modify: `nix/checks/default.nix` - verifies the evaluated Git configuration.

### Task 1: Configure Pull Auto-Stash

**Files:**

- Modify: `nix/checks/default.nix:78-90`
- Modify: `nix/home/programs/git/default.nix:15-38`

- [ ] **Step 1: Write the failing configuration assertion**

Add the pull auto-stash assertion beside the existing Git setting assertions in
`nix/checks/default.nix`:

```nix
assert configuration.config.programs.git.settings.pull.autoStash;
```

- [ ] **Step 2: Run the integration check to verify it fails**

Run:

```bash
nix build .#checks.aarch64-darwin.git-wt-integration --no-link
```

Expected: evaluation fails because the `autoStash` attribute is missing.

- [ ] **Step 3: Add the minimal Git setting**

Add the pull setting beside the existing top-level Git settings in
`nix/home/programs/git/default.nix`:

```nix
pull.autoStash = true;
```

- [ ] **Step 4: Format and run verification**

Run:

```bash
nix fmt -- --check nix/checks/default.nix nix/home/programs/git/default.nix
nix build .#checks.aarch64-darwin.git-wt-integration --no-link
nix flake check --no-build
git diff --check origin/main...HEAD
```

Expected: formatting reports no changes, the integration check builds, the
flake evaluates successfully, and the diff check reports no errors.

- [ ] **Step 5: Commit the implementation**

```bash
git add docs/superpowers/plans/2026-08-16-git-pull-autostash.md \
  nix/checks/default.nix nix/home/programs/git/default.nix
git commit -m "feat(git): auto-stash changes before pull rebase"
```
