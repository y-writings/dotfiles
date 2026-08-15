# Git Pull Rebase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Manage the global Git `pull.rebase` setting as `true` through Home Manager.

**Architecture:** Extend the existing `programs.git.settings` attribute set
rather than introducing another Git configuration path. Protect the generated
value with an assertion in the existing Git integration check.

**Tech Stack:** Nix, Home Manager, Git

---

## File Structure

- Modify: `nix/home/programs/git/default.nix` - owns global Git settings.
- Modify: `nix/checks/default.nix` - verifies the evaluated Git configuration.

### Task 1: Configure Pull Rebase

**Files:**

- Modify: `nix/checks/default.nix:78-89`
- Modify: `nix/home/programs/git/default.nix:15-37`

- [ ] **Step 1: Write the failing configuration assertion**

Add the pull setting assertion beside the existing Git setting assertions in
`nix/checks/default.nix`:

```nix
assert configuration.config.programs.git.settings.pull.rebase;
```

- [ ] **Step 2: Run the integration check to verify it fails**

Run:

```bash
nix build .#checks.aarch64-darwin.git-wt-integration --no-link
```

Expected: evaluation fails because
`configuration.config.programs.git.settings.pull.rebase` does not exist.

- [ ] **Step 3: Add the minimal Git setting**

Add the pull setting beside the existing top-level Git settings in
`nix/home/programs/git/default.nix`:

```nix
pull.rebase = true;
```

- [ ] **Step 4: Format and run verification**

Run:

```bash
nix fmt nix/checks/default.nix nix/home/programs/git/default.nix
nix build .#checks.aarch64-darwin.git-wt-integration --no-link
nix flake check --no-build
git diff --check
```

Expected: formatting makes no unrelated changes, the integration check builds,
the flake evaluates successfully, and `git diff --check` reports no errors.

- [ ] **Step 5: Commit the implementation**

```bash
git add nix/checks/default.nix nix/home/programs/git/default.nix docs/superpowers/plans/2026-08-15-git-pull-rebase.md
git commit -m "feat(git): rebase pulls by default"
```
