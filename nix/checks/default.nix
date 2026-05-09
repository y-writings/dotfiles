{
  inputs,
  hostSystem,
  homeModule,
  mkDarwinSystem,
}:
let
  username = "public";
  homeDir = "/Users/${username}";
  workspacePath = "${homeDir}/workspace";
  ghqRootPath = "${workspacePath}/repos";
  dotfilesRoot = toString ../..;
  paths = {
    inherit
      homeDir
      dotfilesRoot
      workspacePath
      ghqRootPath
      ;
  };

  pkgs = import inputs.nixpkgs {
    system = hostSystem;
    config.allowUnfree = true;
  };

  homeArgs = {
    inherit
      inputs
      paths
      ;
    gitIdentity = {
      name = "Public User";
      email = "public@example.com";
    };
    secrets = { };
  };

  baseSystemArgs = {
    system = hostSystem;
    inherit
      username
      paths
      ;
    gitIdentity = {
      name = "Public User";
      email = "public@example.com";
    };
    enabledInstallFeatures = [ ];
    secrets = { };
  };

  overlayMarker = "private-overlay-marker";

  homeConfiguration =
    extraModules:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = homeArgs;
      modules = [
        homeModule
        {
          home = {
            inherit username;
            homeDirectory = paths.homeDir;
            stateVersion = "25.11";
          };
        }
      ]
      ++ extraModules;
    };
in
{
  exported-home-base = (homeConfiguration [ ]).activationPackage;

  exported-home-overlay =
    (homeConfiguration [
      {
        xdg.configFile."overlay-marker".text = overlayMarker;
      }
    ]).activationPackage;

  exported-darwin-base = (mkDarwinSystem baseSystemArgs).config.system.build.toplevel;

  exported-darwin-overlay =
    let
      systemWithOverlays = mkDarwinSystem (
        baseSystemArgs
        // {
          extraHomeModules = [
            (
              {
                lib,
                ...
              }:
              {
                xdg.configFile."overlay-marker".text = overlayMarker;
                programs.git.settings.alias.graph = lib.mkForce overlayMarker;
              }
            )
          ];
          extraDarwinModules = [
            (
              {
                lib,
                ...
              }:
              {
                environment.etc."overlay-marker".text = overlayMarker;
                nix.settings.extra-substituters = lib.mkAfter [ "https://overlay.example.invalid" ];
              }
            )
          ];
        }
      );
    in
    pkgs.runCommand "exported-darwin-overlay-check" { } ''
      test -f ${systemWithOverlays.config.system.build.toplevel}/etc/overlay-marker
      test "$(cat ${systemWithOverlays.config.system.build.toplevel}/etc/overlay-marker)" = '${overlayMarker}'
      test -f ${
        systemWithOverlays.config.home-manager.users.${username}.xdg.configFile."overlay-marker".source
      }
      test "$(cat ${
        systemWithOverlays.config.home-manager.users.${username}.xdg.configFile."overlay-marker".source
      })" = '${overlayMarker}'
      test '${
        systemWithOverlays.config.home-manager.users.${username}.programs.git.settings.alias.graph
      }' = '${overlayMarker}'
      test '${builtins.toJSON systemWithOverlays.config.nix.settings.extra-substituters}' = '["https://cache.nixos.org/","https://yazi.cachix.org","https://overlay.example.invalid"]'
      touch "$out"
    '';
}
