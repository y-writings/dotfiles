{ ... }:
{
  imports = [
    ./packages.nix
    ./files
    ./programs/zsh
    ./programs/git
    ./programs/yazi
    ./programs/vscode
    ./programs/starship
    ./programs/zoxide
    ./programs/fzf
    ./programs/mise
    ./programs/zellij
    ./programs/ghostty
  ];

  home.stateVersion = "25.11";
}
