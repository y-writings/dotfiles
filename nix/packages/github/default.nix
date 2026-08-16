{ pkgs }:
{
  agent-slack = pkgs.callPackage ./agent-slack.nix { };
  codex-acp = pkgs.callPackage ./codex-acp.nix { };
  difit = pkgs.callPackage ./difit.nix { };
}
