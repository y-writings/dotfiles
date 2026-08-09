# Ghostty Monaspace Font Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Use Monaspace Neon Frozen as Ghostty's primary font while preserving
the existing Japanese fallback font.

**Architecture:** Update the first entry in Home Manager's declarative Ghostty
`font-family` list. Evaluate the module directly to verify both font names and
their fallback order, then run the repository's Nix checks.

**Tech Stack:** Nix, Home Manager, Ghostty

---

## File Structure

- Modify: `nix/home/programs/ghostty/default.nix` - owns Ghostty settings.
- Reference: approved behavior and scope at
  `docs/superpowers/specs/2026-08-09-ghostty-monaspace-font-design.md`.

### Task 1: Change the Ghostty Primary Font

**Files:**

- Modify: `nix/home/programs/ghostty/default.nix:38-41`
- Test: Direct Nix evaluation of `programs.ghostty.settings."font-family"`

- [ ] **Step 1: Run the focused evaluation to verify the requested font list is
      absent**

Run:

```bash
nix eval --raw --impure --expr '
  let
    module = import ./nix/home/programs/ghostty {
      paths.workspacePath = "/tmp/workspace";
    };
    expected = [ "Monaspace Neon Frozen" "UDEV Gothic 35NFLG" ];
  in
  if module.programs.ghostty.settings."font-family" == expected
  then "ok"
  else throw "Ghostty font-family does not match the requested order"'
```

Expected: FAIL with
`Ghostty font-family does not match the requested order`.

- [ ] **Step 2: Replace the primary font entry**

In `nix/home/programs/ghostty/default.nix`, update the existing list:

```nix
      "font-family" = [
        "Monaspace Neon Frozen"
        "UDEV Gothic 35NFLG"
      ];
```

- [ ] **Step 3: Run the focused evaluation again**

Run:

```bash
nix eval --raw --impure --expr '
  let
    module = import ./nix/home/programs/ghostty {
      paths.workspacePath = "/tmp/workspace";
    };
    expected = [ "Monaspace Neon Frozen" "UDEV Gothic 35NFLG" ];
  in
  if module.programs.ghostty.settings."font-family" == expected
  then "ok"
  else throw "Ghostty font-family does not match the requested order"'
```

Expected: command succeeds and prints `ok`.

- [ ] **Step 4: Check Nix formatting**

Run:

```bash
nix fmt -- --check nix/home/programs/ghostty/default.nix
```

Expected: command exits successfully without changing the file.

- [ ] **Step 5: Evaluate all public flake checks**

Run:

```bash
nix flake check path:. \
  --all-systems \
  --no-build \
  --no-update-lock-file \
  --keep-going
```

Expected: all flake checks evaluate successfully.

- [ ] **Step 6: Inspect the implementation diff**

Run:

```bash
git diff --check
git diff -- nix/home/programs/ghostty/default.nix
```

Expected: no whitespace errors and exactly one font-family entry changes.

- [ ] **Step 7: Commit the implementation**

Run:

```bash
git add nix/home/programs/ghostty/default.nix
git commit -m "chore(ghostty): use Monaspace Neon Frozen"
```

Expected: pre-commit and commit-msg hooks pass and the commit is created.
