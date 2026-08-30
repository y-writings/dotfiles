# GitHub Package Bulk Update Policy Design

## Goal

Allow each package under `nix/packages/github` to declare whether the
repository's shared GitHub package updater should update it. Continue to update
`codex-acp` and `difit` through the existing mise `update` task.

## Package Metadata

Every GitHub package derivation must define a boolean
`passthru.updateWithBulkUpdater` value. The initial policy is:

- `codex-acp`: `true`
- `difit`: `true`

The explicit value is required for every current and future package. There is
no default because an omitted value could silently opt a package into or out
of updates.

The name describes the shared updater that enforces the policy. It does not
imply that a package cannot be edited or updated outside the repository's
standard update flow.

## Update Flow

`scripts/update-github-packages.sh` evaluates the package set and reads each
package's `passthru.updateWithBulkUpdater` value before invoking `nix-update`.
It updates only packages whose value is `true` and reports packages skipped
because their value is `false`.

The existing mise `update` task continues to call the script unchanged.
Package exposure through flake outputs and installation through Home Manager
also remain unchanged because `passthru` metadata does not alter the package
set or derivations.

If all registered packages opt out, the updater exits successfully so the
mise task can continue to `nix flake check --no-build`.

## Failure Behavior

The updater fails before updating any package when a registered package omits
`passthru.updateWithBulkUpdater` or assigns a non-boolean value. This makes the
required policy explicit and avoids partially applying updates under an
invalid registry configuration.

Once metadata validation succeeds, the existing sequential, fail-fast update
behavior remains unchanged. A failed `nix-update` preserves earlier edits in
the worktree for review.

## Verification

- Assert that every registered GitHub package declares a boolean
  `passthru.updateWithBulkUpdater` value.
- Assert that `codex-acp` and `difit` are included in bulk updates.
- Retain Bash syntax and ShellCheck validation for the updater.
- Run the focused Nix checks and `nix flake check --no-build`.
- Confirm formatting and whitespace checks pass.
