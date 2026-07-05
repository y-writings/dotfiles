{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    package = pkgs.mise;

    globalConfig = {
      tools = {
        bun = "1.3.11";
        go = "1.26.3";
        terraform = "1.15.7";
      };
    };
  };

  xdg.configFile."mise/config.toml".force = true;
}
