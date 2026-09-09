{ inputs, pkgs }:
[
  inputs.driftline.packages.${pkgs.system}.driftline
  inputs.skills-reconcile.packages.${pkgs.system}.skills-reconcile
]
