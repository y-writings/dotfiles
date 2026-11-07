{ inputs, pkgs }:
[
  inputs.driftline.packages.${pkgs.stdenv.hostPlatform.system}.driftline
  inputs.skills-reconcile.packages.${pkgs.stdenv.hostPlatform.system}.skills-reconcile
]
