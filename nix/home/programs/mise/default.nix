{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    package = pkgs.mise;
  };
}
