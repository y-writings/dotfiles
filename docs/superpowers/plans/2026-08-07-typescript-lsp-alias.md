# TypeScript LSP Alias Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an interactive Zsh alias named `typescript-lsp` that invokes the
installed `typescript-language-server` command.

**Architecture:** Extend the existing Home Manager
`programs.zsh.shellAliases` attribute set. Verify the exact attribute value
directly through Nix evaluation, then run formatting and repository checks.

**Tech Stack:** Nix, Home Manager, Zsh

---

## File Structure

- Modify: `nix/home/programs/zsh/default.nix` - owns declarative Zsh aliases.
- Reference: approved behavior and scope at
  `docs/superpowers/specs/2026-08-07-typescript-lsp-alias-design.md`.

### Task 1: Add the TypeScript LSP Alias

**Files:**

- Modify: `nix/home/programs/zsh/default.nix:24-46`
- Test: Direct Nix evaluation of `programs.zsh.shellAliases."typescript-lsp"`

- [ ] **Step 1: Run the focused evaluation to verify the alias is absent**

Run:

```bash
nix eval --raw --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    pkgs = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin;
    module = import ./nix/home/programs/zsh {
      inherit pkgs;
      lib = pkgs.lib;
      config = {
        home.homeDirectory = "/Users/test";
      };
      inputs = flake.inputs;
      paths = {
        ghqRootPath = "/tmp/repos";
        workspacePath = "/tmp/workspace";
      };
      secrets = { };
    };
  in
  module.programs.zsh.shellAliases."typescript-lsp"'
```

Expected: FAIL with `attribute 'typescript-lsp' missing`.

- [ ] **Step 2: Add the minimal alias declaration**

In `nix/home/programs/zsh/default.nix`, add the alias to the existing
`shellAliases` set:

```nix
      rp = "realpath";
      sg = "ast-grep";
      "typescript-lsp" = "typescript-language-server";
      pbc = "pbcopy";
```

- [ ] **Step 3: Run the focused evaluation to verify the alias value**

Run:

```bash
nix eval --raw --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    pkgs = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin;
    module = import ./nix/home/programs/zsh {
      inherit pkgs;
      lib = pkgs.lib;
      config = {
        home.homeDirectory = "/Users/test";
      };
      inputs = flake.inputs;
      paths = {
        ghqRootPath = "/tmp/repos";
        workspacePath = "/tmp/workspace";
      };
      secrets = { };
    };
  in
  module.programs.zsh.shellAliases."typescript-lsp"'
```

Expected: command succeeds and prints `typescript-language-server`.

- [ ] **Step 4: Check Nix formatting**

Run:

```bash
nix fmt -- --check nix/home/programs/zsh/default.nix
```

Expected: command exits successfully without changing the file.

- [ ] **Step 5: Run repository checks**

Run:

```bash
nix flake check --no-build
```

Expected: all flake checks evaluate successfully.

- [ ] **Step 6: Inspect the final diff**

Run:

```bash
git diff --check
git diff -- \
  nix/home/programs/zsh/default.nix \
  docs/superpowers/specs/2026-08-07-typescript-lsp-alias-design.md \
  docs/superpowers/plans/2026-08-07-typescript-lsp-alias.md
```

Expected: no whitespace errors; the implementation diff contains only the
alias addition, alongside the approved spec and this plan. No commit is created
unless the user explicitly requests one.
