# System Activation Boundary Design

## Goal

Replace Gemini CLI with Antigravity CLI while preventing package-management
requests in this declarative dotfiles repository from being interpreted as
permission to mutate the active machine. Preserve the ability to rebuild when
the user explicitly requests it in unambiguous terms.

## Policy

Requests to install, uninstall, replace, or move packages mean updating the
repository's declarative configuration and verifying that configuration by
default. They do not authorize activation commands.

Activation is authorized only when the user explicitly asks for it in the
current conversation with wording that cannot reasonably be mistaken, such as
`rebuildして`. Generic package-management wording does not authorize activation.

Formatting, evaluation, checks, metadata inspection, and builds that do not
change the active system are verification, not activation.

## Enforcement Layers

### Repository Instructions

Add a root `AGENTS.md` that defines the distinction between declarative changes,
verification, and activation for every agent working in this repository.

### Package Skill

Add an activation policy to `.agents/skills/install-pkgs/SKILL.md`. The policy
must prohibit activation unless the current conversation contains an explicit,
unambiguous request, and must keep activation outside the verification
checklist.

### Project OpenCode Permissions

Add `.opencode/opencode.json` so the command guard applies only inside this
project. Configure mutating commands such as `sudo`, nix-darwin or Home Manager
switches, the repository rebuild task, and direct package-manager installation
or removal commands as `ask`.

The static permission prompt remains in effect even after an explicit rebuild
request. The explicit request satisfies the agent policy; the OpenCode prompt
provides a separate execution-time confirmation.

## Scope

- Create `AGENTS.md`.
- Update `.agents/skills/install-pkgs/SKILL.md`.
- Create `.opencode/opencode.json`.
- Replace `gemini-cli` with `antigravity-cli` in
  `nix/home/packages-unstable.nix`.
- Do not run a rebuild or otherwise activate the changed configuration.
- Do not alter unrelated user changes already present in the worktree.

## Verification

- Validate `.opencode/opencode.json` as JSON and against the OpenCode schema.
- Confirm broad command permissions precede narrower `ask` rules because the
  last matching OpenCode permission rule wins.
- Search all three files for consistent activation terminology and covered
  command families.
- Evaluate and build the configured Antigravity CLI package without activating
  it.
- Inspect the final diff and confirm no activation command was executed.
