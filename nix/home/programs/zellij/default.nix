{ ... }:
{
  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    extraConfig = builtins.readFile ./config.kdl;
  };
}
