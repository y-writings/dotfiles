{
  description = "Determinate nix-darwin system flake with Neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "github:DeterminateSystems/determinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    ni-zsh = {
      url = "github:azu/ni.zsh";
      flake = false;
    };

    user-config = {
      url = "path:./nix/user-config-placeholder";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      determinate,
      home-manager,
      nix-homebrew,
      ...
    }@inputs:
    let
      userConfig = import ./nix/user.nix {
        userConfigRoot = inputs.user-config;
      };
      inherit (userConfig)
        username
        homeDir
        gitIdentity
        dotfilesRoot
        secrets
        ;

      workspacePath = "${homeDir}/workspace";
      enabledInstallFeatures = userConfig.enabledInstallFeatures or [ ];
      ghqRootPath = "${workspacePath}/repos";
      hostSystem = "aarch64-darwin";

      hostname = "${username}-${hostSystem}";
    in
    {

      darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
        system = hostSystem;
        specialArgs = {
          inherit
            username
            gitIdentity
            dotfilesRoot
            enabledInstallFeatures
            workspacePath
            ghqRootPath
            ;
        };

        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew.enable = true;
            nix-homebrew.user = username;
          }
          ./nix/darwin
          { nixpkgs.config.allowUnfree = true; }

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              inherit
                inputs
                gitIdentity
                secrets
                dotfilesRoot
                workspacePath
                ghqRootPath
                ;
            };
            home-manager.users.${username} = import ./nix/home;

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
                home = homeDir;
              };

              security.pam.services.sudo_local.touchIdAuth = true;
              programs.zsh.enable = true;
            }
          )
        ];
      };
    };
}
