{
  gitIdentity,
  ghqRootPath,
  ...
}:
{
  programs.git = {
    enable = true;

    includes = [
      {
        path = "~/.config/nix/git/config";
      }
    ];

    settings = {
      user = {
        name = gitIdentity.name;
        email = gitIdentity.email;
      };
      alias = {
        graph = "log --graph --all --color --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'";
      };
      init.defaultBranch = "main";
      ghq.root = ghqRootPath;

      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };

      gtr.editor.default = "code";
      gtr.ai.default = "codex";
    };
  };
}
