{ pkgs }:
{
  codex-acp = pkgs.callPackage ./codex-acp.nix { };
  difit = pkgs.callPackage ./difit.nix { };
}
