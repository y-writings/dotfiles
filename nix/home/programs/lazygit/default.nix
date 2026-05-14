{ pkgs, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        paging = {
          colorArg = "always";
        };
        pagers = [
          {
            pager = "delta --dark --paging=never";
          }
        ];
      };
      customCommands = [
        {
          key = "<c-t>";
          context = "commits";
          description = "選択中コミットの日時を現在日時に更新";
          prompts = [
            {
              type = "confirm";
              title = "Commit日時更新";
              body = "{{.SelectedLocalCommit.Sha}} の日時を現在日時に変更しますか？";
            }
          ];
          command = "TARGET_SHA={{.SelectedLocalCommit.Sha}}; NOW=$(date -u '+%Y-%m-%dT%H:%M:%SZ'); BRANCH=$(git branch --show-current); git filter-branch -f --env-filter 'if [ \"$GIT_COMMIT\" = \"'$TARGET_SHA'\" ]; then export GIT_AUTHOR_DATE=\"'$NOW'\"; export GIT_COMMITTER_DATE=\"'$NOW'\"; fi' -- \"$BRANCH\"";
          output = "terminal";
          loadingText = "コミット日時を更新中...";
        }
      ];
    };
  };
}
