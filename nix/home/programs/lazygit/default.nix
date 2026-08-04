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
          description = "選択コミット以降の日時を現在日時に更新";
          prompts = [
            {
              type = "confirm";
              title = "Commit日時更新";
              body = "選択コミットから現在のHEADまでの作者日時とコミッター日時を同一の現在日時に変更し、選択コミット以降のコミットIDを書き換えます。実行しますか？";
            }
          ];
          command = ''
            selected='{{.SelectedCommit.Hash}}'

            if ! git merge-base --is-ancestor "$selected" HEAD; then
              printf '%s\n' '選択コミットは現在のHEADの祖先ではありません。' >&2
              exit 1
            fi

            if git rev-parse --verify -q "$selected^" >/dev/null; then
              revision_range="$selected^..HEAD"
              rebase_target="$selected^"
            else
              revision_range=HEAD
              rebase_target=--root
            fi

            if [ -n "$(git rev-list --merges --max-count=1 "$revision_range")" ]; then
              printf '%s\n' '選択コミットから現在のHEADまでにマージコミットが含まれるため、実行できません。' >&2
              exit 1
            fi

            rewrite_date="$(date -u '+%s +0000')"

            GIT_SEQUENCE_EDITOR=: git rebase -i \
              --no-autosquash \
              --no-autostash \
              --no-update-refs \
              --exec "GIT_AUTHOR_DATE='$rewrite_date' GIT_COMMITTER_DATE='$rewrite_date' git commit --amend --allow-empty --no-edit --no-verify --date='$rewrite_date'" \
              "$rebase_target"
          '';
          output = "terminal";
          loadingText = "コミット日時を更新中...";
        }
      ];
    };
  };
}
