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

  exported-darwin-base = (mkDarwinSystem baseSystemArgs).config.system.build.toplevel;
}
