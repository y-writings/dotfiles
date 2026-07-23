# LazyGit Commit Retiming Design

## Goal

Update the author and committer dates of one selected commit or a selected
commit range to the current UTC time from LazyGit. Preserve both dates on
every nonselected commit, including descendants that receive new commit IDs
because their parent changed.

## Scope

- Replace the existing interactive-rebase implementation in
  `nix/home/programs/lazygit/default.nix`.
- Keep the `Ctrl+T` keybinding, confirmation interaction, terminal output, and
  loading text. Update the confirmation body to warn that descendant commit IDs
  are rewritten.
- Do not add `git-filter-repo`, create a temporary clone, or push to a remote.
- Do not preserve rewritten commit IDs or signatures; Git object identity and
  signatures necessarily change when a selected commit's timestamp changes.

## Command Flow

1. Resolve `From` and `To` from `SelectedCommitRange`. LazyGit provides this
   range object for both a single selected commit and a multiple-commit range.
2. Require an attached local branch. Abort before rewriting when HEAD is
   detached, `From` is not an ancestor of `To`, or `To` is not reachable from
   the current branch.
3. Construct the selected revision set as `From^..To`; when `From` is the root
   commit, use `To` so the set includes the root through the selected endpoint.
4. Convert the selected full SHA list into colon-delimited values. Matching
   `:$GIT_COMMIT:` against that list prevents abbreviated-SHA and prefix-match
   errors.
5. Run `git filter-branch --original` with a unique namespace derived from the
   pre-rewrite HEAD and the shell PID. For only the matching original commits,
   set `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE` to `date -u '+%s +0000'`.
   Only after a successful rewrite, update the stable
   `refs/lazygit/retime-last/refs/heads/<branch>` rollback ref.

`git filter-branch` reconstructs all commits reachable from the current branch
but initializes each nonmatching commit's metadata from its original object.
The env filter changes only the selected commits' two date fields, so later
commits retain their original author and committer dates.

## Safety And Recovery

- `git filter-branch` requires a clean worktree and aborts before rewriting if
  it is dirty.
- The confirmation prompt states that the selected dates and all descendant
  hashes will be rewritten. No remote is pushed automatically.
- Before moving the branch, `git filter-branch` writes its previous ref to a
  unique `refs/lazygit/retime-original/<old-head>-<pid>/` namespace. On
  success, the command points `refs/lazygit/retime-last/refs/heads/<branch>`
  at that previous branch tip. This provides a stable immediate rollback ref.
- A failed rewrite leaves `retime-last` unchanged. Neither successful nor
  failed retiming operations remove refs under Git's shared `refs/original/`
  namespace.

## Verification

- Add a regression check using an ephemeral Git repository with commits before,
  within, and after a selected range.
- Verify that both dates on selected commits equal the supplied UTC timestamp.
- Verify that both dates on commits before and after the range retain their
  original values.
- Cover a single selected commit and a range whose first commit is the root.
- Reject a detached HEAD and a range whose lower endpoint is outside the
  current branch without moving the branch ref.
- Verify an existing unrelated `refs/original/` ref survives and the command's
  dedicated rollback ref points to the prior branch tip.
- Verify a dirty worktree rejects the rewrite without removing an existing
  rollback ref, and verify a valid range on a different branch is rejected.
- Run `nixfmt --check` for modified Nix files and `nix flake check --no-build`.
