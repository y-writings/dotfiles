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
      hostSystem = "aarch64-darwin";

      homeModule = import ./nix/home;
      darwinModule = import ./nix/darwin;

      mkDarwinSystem = import ./nix/lib/mk-darwin-system.nix {
        inherit
          inputs
          nix-darwin
          home-manager
          nix-homebrew
          determinate
          homeModule
          darwinModule
          ;
      };

      userConfigPath = builtins.toPath "${toString inputs.user-config}/user.toml";
    in
    {
      homeModules.default = homeModule;
      darwinModules.default = darwinModule;

      darwinConfigurations =
        if builtins.pathExists userConfigPath then
          let
            userConfig = import ./nix/user.nix {
              userConfigRoot = inputs.user-config;
            };
            inherit (userConfig)
              username
              homeDir
              dotfilesRoot
              enabledInstallFeatures
              secrets
              gitIdentity
              ;

            workspacePath = "${homeDir}/workspace";
            ghqRootPath = "${workspacePath}/repos";
            hostname = "${username}-${hostSystem}";
          in
          {
            ${hostname} = mkDarwinSystem {
              system = hostSystem;
              inherit
                username
                homeDir
                dotfilesRoot
                enabledInstallFeatures
                workspacePath
                ghqRootPath
                secrets
                gitIdentity
                ;
            };
          }
        else
          { };

      checks.${hostSystem} = import ./nix/checks {
        inherit
          inputs
          hostSystem
          homeModule
          mkDarwinSystem
          ;
      };
    };
}
