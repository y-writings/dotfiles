{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    package = pkgs.mise;

    globalConfig = {
      settings.idiomatic_version_file_enable_tools = [ "node" ];

      tools = {
        bun = "1.4.3";
        go = "1.27.3";
        terraform = "1.17.0";
      };
    };
  };

  xdg.configFile."mise/config.toml".force = true;
}
