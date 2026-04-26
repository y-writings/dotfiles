{ pkgs, inputs, ... }:
let
  pinnedMisePkgs = inputs.nixpkgs-mise-pinned.legacyPackages.${pkgs.system};
in
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    # Temporary Darwin workaround: pin mise to the exact nixpkgs revision from
    # the pre-update flake.lock, because the current lock hangs while building
    # the transitive direnv used by newer package graph resolution.
    package = pinnedMisePkgs.mise;
  };
}
