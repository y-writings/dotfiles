{ pkgs, inputs, ... }:
let
  unstablePackages = import ./packages-unstable.nix { inherit pkgs; };
  githubPackages = import ../packages/github { inherit pkgs; };
  flakeInputPackages = import ./packages-flake-inputs.nix { inherit pkgs inputs; };
in
{
  home.packages = unstablePackages ++ builtins.attrValues githubPackages ++ flakeInputPackages;
}
