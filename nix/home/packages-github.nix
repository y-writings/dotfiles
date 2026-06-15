{ pkgs, inputs }:
let
  # Fallback wrapper for tools not yet packaged in nixpkgs.
  difitFromGitHub = pkgs.writeShellApplication {
    name = "difit";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      exec ${pkgs.nodejs}/bin/npx --yes difit "$@"
    '';
  };
in
[
  difitFromGitHub
  inputs.driftline.packages.${pkgs.system}.driftline
]
