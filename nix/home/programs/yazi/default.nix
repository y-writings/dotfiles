{ ... }:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";
    enableZshIntegration = true;
    settings = {
      opener.zed = [
        {
          run = "zed %s";
          orphan = true;
          desc = "Zed";
          for = "macos";
        }
      ];

      open.append_rules = [
        {
          url = "*/";
          use = [
            "open"
            "zed"
          ];
        }
      ];
    };
  };
}
