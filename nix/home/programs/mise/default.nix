{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    package = pkgs.mise;

    globalConfig = {
      settings.idiomatic_version_file_enable_tools = [ "node" ];

      tools = {
        bun = "1.3.11";
        go = "1.26.3";
        terraform = "1.15.7";
      };
    };
  };

  xdg.configFile."mise/config.toml".force = true;
}
