# LazyGit Hunk Pager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Hunk LazyGit's default embedded diff pager, retain LazyGit's
built-in renderer as a fallback, and migrate the existing Hunk installation from
its retired tap to Homebrew Core.

**Architecture:** LazyGit will pipe uncolored Git patches to Hunk's
non-interactive static pager renderer using settings local to the pager entry.
The existing delta Home Manager configuration remains untouched, so command-line
Git behavior does not change. Homebrew continues to own Hunk, but through the
Core formula instead of `modem-dev/tap`.

**Tech Stack:** Nix, Home Manager, nix-darwin, nix-homebrew, LazyGit, Hunk,
Homebrew

---

## Task 1: Configure LazyGit's Hunk pager

**Files:**

- Modify: `nix/home/programs/lazygit/default.nix:7-16`

- [ ] **Step 1: Confirm the current pager does not satisfy the design**

Run:

```bash
nix eval --json --impure --expr '
  (import ./nix/home/programs/lazygit {
    pkgs = null;
  }).programs.lazygit.settings.git
'
```

Expected: output contains `delta --dark --paging=never`, contains the old
`paging.colorArg` field, and does not contain `hunk pager`.

- [ ] **Step 2: Replace the pager configuration**

Change the `git` settings to:

```nix
git = {
  pagers = [
    {
      name = "Hunk";
      colorArg = "never";
      pager = "hunk pager --mode stack --line-numbers --hunk-headers --no-wrap --transparent-bg";
    }
    { }
  ];
};
```

Keep `customCommands` unchanged.

- [ ] **Step 3: Evaluate the resulting LazyGit settings**

Run:

```bash
nix eval --json --impure --expr '
  (import ./nix/home/programs/lazygit {
    pkgs = null;
  }).programs.lazygit.settings.git
'
```

Expected: `pagers[0]` has name `Hunk`, `colorArg` equal to `never`, and the
complete Hunk command; `pagers[1]` is `{}`; no `paging` field exists.

- [ ] **Step 4: Format-check the LazyGit module**

Run:

```bash
nix fmt -- --check nix/home/programs/lazygit/default.nix
```

Expected: exit code 0 with no formatting changes.

## Task 2: Migrate Hunk to Homebrew Core

**Files:**

- Modify: `nix/darwin/homebrew.nix:12-40`

- [ ] **Step 1: Confirm the current package source does not satisfy the design**

Run:

```bash
nix eval --json --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    config = import ./nix/darwin/homebrew.nix {
      lib = flake.inputs.nixpkgs.lib;
      enabledInstallFeatures = [];
    };
  in
  {
    inherit (config.nix-homebrew.trust) formulae;
    inherit (config.homebrew) taps brews;
  }
'
```

Expected: all three relevant lists contain a `modem-dev/tap` reference.

- [ ] **Step 2: Replace the tapped formula with the Core formula**

Make these exact changes:

```nix
nix-homebrew.trust = {
  formulae = [ "k1low/tap/mo" ];
  casks = [ "entireio/tap/entire" ];
};
```

Remove `"modem-dev/tap"` from `homebrew.taps`, and use this formula list:

```nix
brews = [
  "agent-browser"
  "homebrew/core/hunk"
  "k1low/tap/mo"
];
```

Keep all unrelated Homebrew entries unchanged.

- [ ] **Step 3: Evaluate the resulting Homebrew intent**

Run:

```bash
nix eval --json --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    config = import ./nix/darwin/homebrew.nix {
      lib = flake.inputs.nixpkgs.lib;
      enabledInstallFeatures = [];
    };
  in
  {
    inherit (config.nix-homebrew.trust) formulae;
    inherit (config.homebrew) taps brews;
  }
'
```

Expected: `brews` contains `homebrew/core/hunk`; no evaluated list contains
`modem-dev/tap`; Hunk is absent from trusted formulae because Homebrew Core does
not require tap trust. This verifies declarative configuration only; it does not
change or verify the source recorded in an existing local Hunk installation
receipt.

- [ ] **Step 4: Document the user-executed one-time source migration**

Before the first nix-darwin activation on a machine with `modem-dev/tap/hunk`
installed, the user must run:

```bash
HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_AUTOREMOVE=1 brew uninstall --formula hunk
HOMEBREW_NO_AUTO_UPDATE=1 brew untap modem-dev/tap
```

Then the user runs the normal nix-darwin switch, which installs
`homebrew/core/hunk`. Do not execute these commands during this coding task
without explicit user authorization. No persistent activation compatibility hook
is needed for this one-time source migration.

Expected: the repository declares the Core formula independently of local
installed provenance; after the user performs the one-time migration and
switches, the installed Hunk formula comes from `homebrew/core`.

- [ ] **Step 5: Format-check the Homebrew module**

Run:

```bash
nix fmt -- --check nix/darwin/homebrew.nix
```

Expected: exit code 0 with no formatting changes.

## Task 3: Verify the integrated configuration

**Files:**

- Verify: `nix/home/programs/lazygit/default.nix`
- Verify: `nix/darwin/homebrew.nix`
- Verify unchanged: `nix/home/programs/git/default.nix`
- Verify unchanged: `nix/home/packages-unstable.nix`

- [ ] **Step 1: Check for stale or duplicate pager and package references**

Run:

```bash
rg -n \
  -e 'modem-dev/tap/hunk|modem-dev/tap|delta --dark|hunk pager' \
  -e 'programs\.delta|^[[:space:]]+delta$' \
  nix
```

Expected: one `hunk pager` reference remains in the LazyGit module; no
`modem-dev/tap` or LazyGit delta command remains; `programs.delta` and the
standalone `delta` package remain present.

- [ ] **Step 2: Run repository checks without building outputs**

Run:

```bash
nix flake check --no-build
```

Expected: exit code 0. Any warning must be reported separately and identified as
new or pre-existing.

- [ ] **Step 3: Smoke-test Hunk's LazyGit static pager path**

Run:

```bash
git diff -- nix/home/programs/lazygit/default.nix \
  | perl -e 'alarm shift; exec @ARGV' 30 \
    script -q /dev/null env TERM=dumb GIT_PAGER=hunk \
    hunk pager --mode stack --line-numbers --hunk-headers \
    --no-wrap --transparent-bg \
  | LC_ALL=C rg -q $'\x1b\\['
```

Expected: exit code 0. macOS `script -q /dev/null` gives Hunk PTY-backed stdout;
`GIT_PAGER=hunk` and `TERM=dumb` trigger Hunk's captured-host static-diff plan
to match LazyGit; Perl's alarm bounds execution to 30 seconds; and
`LC_ALL=C rg -q $'\x1b\\['` requires ANSI escape output so raw pass-through
cannot falsely pass.

- [ ] **Step 4: Inspect only the intended diff**

Run:

```bash
git diff --check -- \
  nix/home/programs/lazygit/default.nix \
  nix/darwin/homebrew.nix \
  docs/superpowers/specs/2026-07-12-lazygit-hunk-pager-design.md \
  docs/superpowers/plans/2026-07-12-lazygit-hunk-pager.md
git diff -- \
  nix/home/programs/lazygit/default.nix \
  nix/darwin/homebrew.nix
```

Expected: no whitespace errors; the code diff contains only the approved LazyGit
pager replacement and Homebrew source migration. The unrelated existing Zed
settings change is absent.

- [ ] **Step 5: Leave changes uncommitted unless explicitly requested**

Do not stage or commit files. Report the changed files and verification results
to the user.
