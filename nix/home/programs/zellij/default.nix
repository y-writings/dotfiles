{ ... }:
{
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = builtins.readFile ./config.kdl;
  };
}
