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
              body = "選択コミットから現在のHEADまでの作者日時とコミッター日時を同一の現在日時に変更し、対象コミットのIDを書き換えます。実行しますか？";
            }
          ];
          command = ''
            selected='{{.SelectedCommit.Hash}}'

            if ! git merge-base --is-ancestor "$selected" HEAD; then
              printf '%s\n' '選択コミットは現在のHEADの祖先ではありません。' >&2
              exit 1
            fi

            rewrite_date="$(date -u '+%s +0000')"

            GIT_SEQUENCE_EDITOR=: git rebase -i \
              --exec "GIT_AUTHOR_DATE='$rewrite_date' GIT_COMMITTER_DATE='$rewrite_date' git commit --amend --no-edit --no-verify --date='$rewrite_date'" \
              "$selected^"
          '';
          output = "terminal";
          loadingText = "コミット日時を更新中...";
        }
      ];
    };
  };
}
