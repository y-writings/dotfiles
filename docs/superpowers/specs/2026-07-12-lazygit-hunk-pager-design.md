# LazyGit Hunk Pager Design

## Goal

Use Hunk as LazyGit's default diff pager while preserving delta as the pager for
normal Git commands. Optimize LazyGit's embedded diff display for reviewing
large, agent-authored changesets without launching a nested interactive TUI.

## Configuration

- Replace LazyGit's delta pager with
  `hunk pager --mode stack --line-numbers --hunk-headers --no-wrap --transparent-bg`.
- Set `colorArg = "never"` on the Hunk pager entry so Hunk receives an
  undecorated patch and applies its own highlighting.
- Remove the obsolete `git.paging.colorArg` shape; current LazyGit configuration
  stores `colorArg` on each `git.pagers` entry.
- Add an empty second pager entry so the `|` key can switch to LazyGit's
  built-in diff renderer.
- Keep Home Manager's `programs.delta` Git integration and the delta package
  unchanged.

Hunk detects LazyGit's constrained pager environment and renders non-interactive
ANSI output. Stack mode fits LazyGit's main panel better than a forced
side-by-side layout. Line numbers and hunk headers retain review context,
disabled wrapping preserves code structure, and a transparent background avoids
a conflicting nested surface.

## Package Migration

Hunk is already installed as a Homebrew formula. Replace the retired
`modem-dev/tap/hunk` reference with the Homebrew Core `homebrew/core/hunk`
formula, then remove the no-longer-needed Hunk tap and trust entry. This follows
Hunk's current installation guidance and does not change its installation
manager.

Before the first nix-darwin activation on a machine with `modem-dev/tap/hunk`
installed, run this one-time migration:

```bash
HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_AUTOREMOVE=1 brew uninstall --formula hunk
HOMEBREW_NO_AUTO_UPDATE=1 brew untap modem-dev/tap
```

Then run the normal nix-darwin switch, which installs `homebrew/core/hunk`. No
persistent compatibility hook is added because changing the installed formula
receipt is a one-time source migration.

## Agent Workflow Boundary

LazyGit's pager host uses Hunk's static renderer, so it cannot expose Hunk's
live session controls or inline agent comments. Interactive agent-assisted
review remains an opt-in workflow started with a standalone `hunk diff` or
`hunk show` session. No misleading `--agent-notes` option is added to the
LazyGit pager.

## Failure Handling

- The built-in LazyGit pager remains available through pager cycling if Hunk
  cannot render a particular diff usefully.
- Hunk's static renderer falls back to the original patch when parsing or
  rendering fails.
- Normal command-line Git paging remains backed by delta and is unaffected.

## Verification

- Format the modified Nix files with the repository formatter in check mode.
- Evaluate the Home Manager and nix-darwin modules affected by the changes.
- Run `nix flake check --no-build`.
- Confirm the generated LazyGit settings contain the Hunk pager followed by the
  built-in pager.
- Run the implementation plan's bounded PTY smoke test and require ANSI output.
  The PTY and captured-host environment trigger the static-diff plan that
  matches LazyGit, while the timeout and ANSI assertion prevent a hang or raw
  pass-through from falsely passing.
- Confirm Homebrew contains one Core `homebrew/core/hunk` formula and no
  `modem-dev/tap` references.
- Confirm delta remains installed and enabled for normal Git integration.
