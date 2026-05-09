{ pkgs, inputs, ... }:
let
  stablePkgs = inputs.nixpkgs-stable.legacyPackages.${pkgs.system};
  stablePackages = import ./packages-stable.nix { inherit stablePkgs; };
  unstablePackages = import ./packages-unstable.nix { inherit pkgs; };
  githubPackages = import ./packages-github.nix { inherit pkgs; };
in
{
  home.packages = unstablePackages ++ stablePackages ++ githubPackages;
}
