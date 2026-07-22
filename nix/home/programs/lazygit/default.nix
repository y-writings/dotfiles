{ pkgs, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
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
      customCommands = [
        {
          key = "<c-t>";
          context = "commits";
          description = "選択コミット(単体/範囲)の日時を現在日時に更新";
          prompts = [
            {
              type = "confirm";
              title = "Commit日時更新";
              body = "選択コミット(単体/範囲)の日時を現在日時に変更し、以降のコミットIDを書き換えます。実行しますか？";
            }
          ];
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
          output = "terminal";
          loadingText = "コミット日時を更新中...";
        }
      ];
    };
  };
}
