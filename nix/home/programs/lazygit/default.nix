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
              body = "選択コミット(単体/範囲)の日時を現在日時に変更しますか？";
            }
          ];
          command = ''
            FROM_SHA={{ if .SelectedCommitRange }}{{ .SelectedCommitRange.From.Hash }}{{ else }}{{ .SelectedCommit.Hash }}{{ end }}
            TO_SHA={{ if .SelectedCommitRange }}{{ .SelectedCommitRange.To.Hash }}{{ else }}{{ .SelectedCommit.Hash }}{{ end }}
            NOW=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
            BASE="''${FROM_SHA}^"
            TARGET_SHAS=$(git rev-list --reverse "''${FROM_SHA}^..''${TO_SHA}" | tr '\n' ' ')

            GIT_SEQUENCE_EDITOR="sh -c 'for sha in ''${TARGET_SHAS}; do sed -i \"s/^pick ''${sha} /edit ''${sha} /\" \"$1\"; done'" git rebase -i "''${BASE}" || exit 1

            while [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; do
              GIT_AUTHOR_DATE="''${NOW}" GIT_COMMITTER_DATE="''${NOW}" git commit --amend --no-edit --date "''${NOW}" || exit 1
              git rebase --continue || exit 1
            done
          '';
          output = "terminal";
          loadingText = "コミット日時を更新中...";
        }
      ];
    };
  };
}
