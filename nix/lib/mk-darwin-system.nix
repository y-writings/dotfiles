{
  inputs,
  nix-darwin,
  home-manager,
  nix-homebrew,
  determinate,
  homeModule,
  darwinModule,
}:
{
  system,
  username,
  paths,
  enabledInstallFeatures ? [ ],
  secrets ? { },
  gitIdentity,
  extraDarwinModules ? [ ],
  extraHomeModules ? [ ],
}:
let
  homeManagerExtraSpecialArgs = {
    inherit
      inputs
      paths
      secrets
      gitIdentity
      ;
  };
in
nix-darwin.lib.darwinSystem {
  inherit system;

  specialArgs = {
    inherit
      username
      enabledInstallFeatures
      ;
  };

  modules = [
    nix-homebrew.darwinModules.nix-homebrew
    {
      nix-homebrew.enable = true;
      nix-homebrew.user = username;
    }
    darwinModule
    { nixpkgs.config.allowUnfree = true; }
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.extraSpecialArgs = homeManagerExtraSpecialArgs;
      home-manager.users.${username} = {
        imports = [ homeModule ] ++ extraHomeModules;
      };
    }
    determinate.darwinModules.default
    (
      { ... }:
      {
        nix.enable = false;
        determinateNix.enable = true;

        system.stateVersion = 6;
        users.users.${username} = {
          name = username;
          home = paths.homeDir;
        };

        security.pam.services.sudo_local.touchIdAuth = true;
        programs.zsh.enable = true;
      }
    )
  ]
  ++ extraDarwinModules;
}
