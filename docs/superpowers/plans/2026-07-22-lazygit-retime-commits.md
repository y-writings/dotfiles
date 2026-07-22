# LazyGit Commit Retiming Implementation Plan

<!-- markdownlint-disable MD013 -->

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make LazyGit's `Ctrl+T` retime one selected commit or a selected range while preserving both dates on every nonselected commit.

**Architecture:** Keep the LazyGit command inline in its existing Home Manager module. The command validates `From -> To -> current branch`, then supplies the selected range to `git filter-branch --env-filter`; the filter changes only matching original commit IDs, so descendants receive new IDs but retain their original author and committer dates. A unique command-owned backup namespace is created for every run, and only a successful rewrite updates the stable `refs/lazygit/retime-last/` rollback ref. A Nix check obtains that exact configured command, substitutes fixed LazyGit template values, and runs it in disposable Git repositories.

**Tech Stack:** Nix, Home Manager, LazyGit custom-command templates, Git `filter-branch`, Bash, Nix flake checks.

---

## Tasks

### Task 1: Add A Failing Retiming Integration Check

**Files:**

- Modify: `nix/checks/default.nix:72-143`
- Test: `nix/checks/default.nix`

- [ ] **Step 1: Add the check and make it expect the replacement command templates**

  Add `lazygitSettings` before the final attribute set, then add the check below
  `git-wt-integration`. The template substitutions deliberately target
  `.SelectedCommitRange.From` and `.To`; the current `.From.Hash` and `.To.Hash`
  command will fail when the check executes.

  ```nix
    lazygitSettings = (import ../home/programs/lazygit { inherit pkgs; }).programs.lazygit.settings;
  in
  {
    # Existing checks...

    lazygit-retime-commits =
      let
        command = (builtins.head lazygitSettings.customCommands).command;
        commandTemplate = builtins.toFile "lazygit-retime-command.sh" command;
      in
      pkgs.runCommand "lazygit-retime-commits-check" {
        nativeBuildInputs = [
          pkgs.bash
          pkgs.git
        ];
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"

        make_repo() {
          repo="$1"
          git init -q "$repo"
          git -C "$repo" config user.name Test
          git -C "$repo" config user.email test@example.com
          GIT_AUTHOR_DATE='2024-01-01T00:00:00Z' GIT_COMMITTER_DATE='2024-01-01T00:00:00Z' git -C "$repo" commit --allow-empty -qm one
          GIT_AUTHOR_DATE='2024-01-02T00:00:00Z' GIT_COMMITTER_DATE='2024-01-02T00:00:00Z' git -C "$repo" commit --allow-empty -qm two
          GIT_AUTHOR_DATE='2024-01-03T00:00:00Z' GIT_COMMITTER_DATE='2024-01-03T00:00:00Z' git -C "$repo" commit --allow-empty -qm three
          GIT_AUTHOR_DATE='2024-01-04T00:00:00Z' GIT_COMMITTER_DATE='2024-01-04T00:00:00Z' git -C "$repo" commit --allow-empty -qm four
        }

        run_command() {
          repo="$1"
          from="$2"
          to="$3"
          script="$TMPDIR/retime.sh"
          ${pkgs.gnused}/bin/sed \
            -e "s#{{.SelectedCommitRange.From}}#$from#g" \
            -e "s#{{.SelectedCommitRange.To}}#$to#g" \
            ${commandTemplate} > "$script"
          chmod +x "$script"
          (
            cd "$repo"
            ${pkgs.bash}/bin/bash "$script"
          )
        }

        assert_date() {
          repo="$1"
          revision="$2"
          expected_author="$3"
          expected_committer="$4"
          test "$(git -C "$repo" show -s --format=%aI "$revision")" = "$expected_author"
          test "$(git -C "$repo" show -s --format=%cI "$revision")" = "$expected_committer"
        }

        invalid_repo="$TMPDIR/invalid"
        make_repo "$invalid_repo"
        invalid_branch=$(git -C "$invalid_repo" branch --show-current)
        git -C "$invalid_repo" branch topic HEAD~3
        git -C "$invalid_repo" switch -q topic
        git -C "$invalid_repo" commit --allow-empty -qm topic
        invalid_from=$(git -C "$invalid_repo" rev-parse HEAD)
        git -C "$invalid_repo" switch -q "$invalid_branch"
        invalid_to=$(git -C "$invalid_repo" rev-parse HEAD~1)
        invalid_tip=$(git -C "$invalid_repo" rev-parse HEAD)
        if run_command "$invalid_repo" "$invalid_from" "$invalid_to"; then
          printf '%s\n' 'accepted a range whose lower endpoint is outside the current branch' >&2
          exit 1
        fi
        test "$(git -C "$invalid_repo" rev-parse HEAD)" = "$invalid_tip"

        unreachable_repo="$TMPDIR/unreachable"
        make_repo "$unreachable_repo"
        unreachable_branch=$(git -C "$unreachable_repo" branch --show-current)
        git -C "$unreachable_repo" branch topic HEAD~3
        git -C "$unreachable_repo" switch -q topic
        git -C "$unreachable_repo" commit --allow-empty -qm topic
        unreachable_from=$(git -C "$unreachable_repo" rev-parse HEAD~1)
        unreachable_to=$(git -C "$unreachable_repo" rev-parse HEAD)
        git -C "$unreachable_repo" switch -q "$unreachable_branch"
        unreachable_tip=$(git -C "$unreachable_repo" rev-parse HEAD)
        if run_command "$unreachable_repo" "$unreachable_from" "$unreachable_to"; then
          printf '%s\n' 'accepted a range outside the current branch' >&2
          exit 1
        fi
        test "$(git -C "$unreachable_repo" rev-parse HEAD)" = "$unreachable_tip"

        detached_repo="$TMPDIR/detached"
        make_repo "$detached_repo"
        git -C "$detached_repo" switch --detach -q HEAD~1
        detached=$(git -C "$detached_repo" rev-parse HEAD)
        if run_command "$detached_repo" "$detached" "$detached"; then
          printf '%s\n' 'accepted a detached HEAD' >&2
          exit 1
        fi
        test "$(git -C "$detached_repo" rev-parse HEAD)" = "$detached"

        dirty_repo="$TMPDIR/dirty"
        make_repo "$dirty_repo"
        dirty_branch=$(git -C "$dirty_repo" branch --show-current)
        printf '%s\n' clean > "$dirty_repo/tracked"
        git -C "$dirty_repo" add tracked
        git -C "$dirty_repo" commit -qm tracked
        dirty_tip=$(git -C "$dirty_repo" rev-parse HEAD)
        dirty_backup_ref="refs/lazygit/retime-original/keep/refs/heads/$dirty_branch"
        dirty_last_ref="refs/lazygit/retime-last/refs/heads/$dirty_branch"
        git -C "$dirty_repo" update-ref "$dirty_backup_ref" "$dirty_tip"
        git -C "$dirty_repo" update-ref "$dirty_last_ref" "$dirty_tip"
        printf '%s\n' modified > "$dirty_repo/tracked"
        dirty_selected=$(git -C "$dirty_repo" rev-parse HEAD~2)
        if run_command "$dirty_repo" "$dirty_selected" "$dirty_selected"; then
          printf '%s\n' accepted a dirty worktree >&2
          exit 1
        fi
        test "$(git -C "$dirty_repo" rev-parse "$dirty_backup_ref")" = "$dirty_tip"
        test "$(git -C "$dirty_repo" rev-parse "$dirty_last_ref")" = "$dirty_tip"

        single_repo="$TMPDIR/single"
        make_repo "$single_repo"
        old_tip=$(git -C "$single_repo" rev-parse HEAD)
        git -C "$single_repo" update-ref refs/original/refs/heads/unrelated "$old_tip"
        selected=$(git -C "$single_repo" rev-parse HEAD~2)
        run_command "$single_repo" "$selected" "$selected"
        selected_author=$(git -C "$single_repo" show -s --format=%aI HEAD~2)
        selected_committer=$(git -C "$single_repo" show -s --format=%cI HEAD~2)
        test "$selected_author" = "$selected_committer"
        test "$selected_author" != '2024-01-02T00:00:00Z'
        case "$selected_author" in *Z) ;; *) exit 1 ;; esac
        assert_date "$single_repo" HEAD~3 '2024-01-01T00:00:00Z' '2024-01-01T00:00:00Z'
        assert_date "$single_repo" HEAD~1 '2024-01-03T00:00:00Z' '2024-01-03T00:00:00Z'
        assert_date "$single_repo" HEAD '2024-01-04T00:00:00Z' '2024-01-04T00:00:00Z'
        test "$(git -C "$single_repo" rev-parse HEAD)" != "$old_tip"
        test "$(git -C "$single_repo" rev-parse refs/original/refs/heads/unrelated)" = "$old_tip"
        if git -C "$single_repo" rev-parse --verify "refs/original/refs/heads/$(git -C "$single_repo" branch --show-current)" >/dev/null 2>&1; then
          printf '%s\n' 'created a default filter-branch backup ref' >&2
          exit 1
        fi
        backup_ref="refs/lazygit/retime-last/refs/heads/$(git -C "$single_repo" branch --show-current)"
        test "$(git -C "$single_repo" rev-parse "$backup_ref")" = "$old_tip"

        root_repo="$TMPDIR/root"
        make_repo "$root_repo"
        root_from=$(git -C "$root_repo" rev-parse HEAD~3)
        root_to=$(git -C "$root_repo" rev-parse HEAD~2)
        run_command "$root_repo" "$root_from" "$root_to"
        root_author=$(git -C "$root_repo" show -s --format=%aI HEAD~3)
        root_committer=$(git -C "$root_repo" show -s --format=%cI HEAD~3)
        test "$root_author" = "$root_committer"
        test "$root_author" != '2024-01-01T00:00:00Z'
        assert_date "$root_repo" HEAD~2 "$root_author" "$root_committer"
        assert_date "$root_repo" HEAD~1 '2024-01-03T00:00:00Z' '2024-01-03T00:00:00Z'
        assert_date "$root_repo" HEAD '2024-01-04T00:00:00Z' '2024-01-04T00:00:00Z'

        touch "$out"
      '';
  }
  ```

- [ ] **Step 2: Run the new check and verify it fails for the current command**

  Run:

  ```bash
  nix build '.#checks.aarch64-darwin.lazygit-retime-commits' --no-link
  ```

  Expected: failure before creating `$out`, because the current command still
  contains `.SelectedCommitRange.From.Hash` and `.To.Hash` rather than the
  test's valid SHA substitutions.

### Task 2: Replace Interactive Rebase With A Date-Only Filter

**Files:**

- Modify: `nix/home/programs/lazygit/default.nix:29-42`
- Test: `nix/checks/default.nix`

- [ ] **Step 1: Replace the custom command body**

  Keep the surrounding keybinding, `output = "terminal"`, and loading text.
  Update the confirmation body to say that descendant commit IDs are rewritten,
  then replace the `command` string with the following body.

  ```nix
  command = ''
    range_from='{{.SelectedCommitRange.From}}'
    range_to='{{.SelectedCommitRange.To}}'
    branch=$(git branch --show-current)

    if [ -z "$branch" ]; then
      printf '%s\n' '現在のブランチでのみ実行できます。' >&2
      exit 1
    fi

    if ! git merge-base --is-ancestor "$range_from" "$range_to" || ! git merge-base --is-ancestor "$range_to" "$branch"; then
      printf '%s\n' '選択範囲は現在のブランチに含まれていません。' >&2
      exit 1
    fi

    if git rev-parse --verify -q "$range_from^" >/dev/null; then
      revision_range="$range_from^..$range_to"
    else
      revision_range="$range_to"
    fi

    rewrite_targets=":$(git rev-list "$revision_range" | tr '\n' ':')"
    rewrite_date="$(date -u '+%s +0000')"
    backup_namespace="refs/lazygit/retime-original/$(git rev-parse HEAD)-$$"
    export rewrite_targets rewrite_date FILTER_BRANCH_SQUELCH_WARNING=1

    git filter-branch --original "$backup_namespace" --env-filter '
      case "$rewrite_targets" in
        *":$GIT_COMMIT:"*)
          GIT_AUTHOR_DATE="$rewrite_date"
          GIT_COMMITTER_DATE="$rewrite_date"
          export GIT_AUTHOR_DATE GIT_COMMITTER_DATE
          ;;
      esac
    ' -- "$branch" &&
      git update-ref "refs/lazygit/retime-last/refs/heads/$branch" "$(git rev-parse "$backup_namespace/refs/heads/$branch")"
  '';
  ```

- [ ] **Step 2: Run the new check and verify it passes**

  Run:

  ```bash
  nix build '.#checks.aarch64-darwin.lazygit-retime-commits' --no-link
  ```

  Expected: success. The single scenario changes only commit `two`; the root
  range scenario changes only commits `one` and `two`; nonselected dates remain
  exactly at their seeded values.

- [ ] **Step 3: Check the generated configuration shape**

  Run:

  ```bash
  nix eval --raw --impure --expr 'let pkgs = import <nixpkgs> { system = "aarch64-darwin"; }; config = import ./nix/home/programs/lazygit { inherit pkgs; }; in (builtins.head config.programs.lazygit.settings.customCommands).command'
  ```

  Expected: the command contains `SelectedCommitRange.From`,
  `git filter-branch`, and `date -u '+%s +0000'`; it contains neither
  `SelectedCommitRange.From.Hash` nor `GIT_SEQUENCE_EDITOR`.

### Task 3: Run Repository Verification

**Files:**

- Modify: `nix/checks/default.nix`
- Modify: `nix/home/programs/lazygit/default.nix`

- [ ] **Step 1: Format the Nix changes**

  Run:

  ```bash
  nix fmt -- nix/checks/default.nix nix/home/programs/lazygit/default.nix
  ```

- [ ] **Step 2: Verify formatting and the targeted history check**

  Run:

  ```bash
  nix fmt -- --check nix/checks/default.nix nix/home/programs/lazygit/default.nix
  nix build '.#checks.aarch64-darwin.lazygit-retime-commits' --no-link
  ```

  Expected: both commands exit successfully.

- [ ] **Step 3: Run the full Nix evaluation check**

  Run:

  ```bash
  nix flake check --no-build
  ```

  Expected: all flake checks evaluate successfully. Existing derivation-context
  warnings may remain, but no new LazyGit or Nix evaluation errors appear.

- [ ] **Step 4: Inspect the final diff**

  Run:

  ```bash
  git diff --check
  git diff -- nix/checks/default.nix nix/home/programs/lazygit/default.nix
  git status --short
  ```

  Expected: only the intended LazyGit command, its regression check, and the
  approved design and plan documents are changed. Do not commit unless the user
  explicitly requests it.
