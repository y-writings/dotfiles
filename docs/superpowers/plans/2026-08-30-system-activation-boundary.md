# System Activation Boundary Implementation Plan

<!-- markdownlint-disable MD013 -->

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Gemini CLI with Antigravity CLI and prevent package requests from implicitly authorizing changes to the active machine.

**Architecture:** Repository instructions and the package-install skill define the semantic boundary between declarative edits, verification, and activation. A project-local OpenCode permission file adds an independent execution-time prompt for commands that mutate the machine.

**Tech Stack:** Markdown agent instructions, OpenCode JSON configuration, Nix, Home Manager

---

## Task 1: Define The Activation Boundary

**Files:**

- Create: `AGENTS.md`
- Modify: `.agents/skills/install-pkgs/SKILL.md`

- [ ] **Step 1: Add repository instructions**

Create `AGENTS.md` with a system activation section that treats package requests as declarative configuration changes, permits non-mutating verification, and requires an explicit unambiguous activation request such as `rebuildして`.

- [ ] **Step 2: Add the package-skill policy**

Add the same activation boundary before the skill's core workflow and state explicitly that its verification checklist never authorizes activation.

- [ ] **Step 3: Check policy consistency**

Run:

```bash
rg -n "declarative|verification|activation|rebuildして" AGENTS.md .agents/skills/install-pkgs/SKILL.md
```

Expected: both files distinguish all three phases and require explicit activation wording.

## Task 2: Add Project-Local Command Guards

**Files:**

- Create: `.opencode/opencode.json`

- [ ] **Step 1: Add OpenCode permissions**

Create a schema-backed project configuration whose broad Bash rule appears first and whose narrower `ask` rules cover `sudo`, rebuild and switch commands, and direct package-manager installation or removal.

- [ ] **Step 2: Validate the configuration**

Run:

```bash
jq empty .opencode/opencode.json
```

Expected: exit status 0.

Fetch `https://opencode.ai/config.json` and validate that `permission.bash` accepts ordered command-pattern actions.

## Task 3: Complete The CLI Replacement

**Files:**

- Modify: `nix/home/packages-unstable.nix`

- [ ] **Step 1: Confirm the package list**

Ensure `antigravity-cli` appears in alphabetical order and `gemini-cli` is absent.

- [ ] **Step 2: Verify package metadata and build**

Run:

```bash
nix eval --raw --impure --expr 'let f = builtins.getFlake (toString ./.); p = f.inputs.nixpkgs.legacyPackages.aarch64-darwin.antigravity-cli; in "${p.version}:${p.meta.mainProgram}"'
NIXPKGS_ALLOW_UNFREE=1 nix build --no-link --impure --expr '(builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.aarch64-darwin.antigravity-cli'
```

Expected: metadata ends in `:agy` and the package builds successfully.

## Task 4: Verify And Publish

**Files:**

- Verify: `AGENTS.md`
- Verify: `.agents/skills/install-pkgs/SKILL.md`
- Verify: `.opencode/opencode.json`
- Verify: `nix/home/packages-unstable.nix`

- [ ] **Step 1: Run focused checks**

Run:

```bash
nix fmt -- --check nix/home/packages-unstable.nix
nix eval .#checks.aarch64-darwin.exported-home-base.drvPath
git diff --check
```

Expected: all commands exit successfully. Pre-existing failures from unrelated modified files must be reported rather than fixed.

- [ ] **Step 2: Review the intended diff**

Inspect only the files listed in this plan. Do not stage the existing changes in `nix/home/files/vscode/settings.json` or `nix/home/files/zed/keymap.json`.

- [ ] **Step 3: Commit and create the pull request**

Create a feature branch, commit only the intended files using the repository's Conventional Commit style, push it, and create a GitHub pull request containing the motivation and verification evidence.
