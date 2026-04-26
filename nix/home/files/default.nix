{
  config,
  paths,
  ...
}:
let
  filesDir = "${paths.dotfilesRoot}/nix/home/files";
in
{
  xdg.enable = true;

  home.file.".local/bin/wbin" = {
    source = ./bin/wbin;
    executable = true;
  };

  home.file."workspace/bin/README.md".source = ./workspace/bin/README.md;
  home.file."workspace/assets/vscode-custom-css/custom.css".source =
    ./vscode/assets/vscode-custom-css/custom.css;

  home.file.".vrapperrc".source = ./vrapper/.vrapperrc;

  home.file."Library/Application Support/Code/User/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${filesDir}/vscode/settings.json";

  home.file."Library/Application Support/Code/User/keybindings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${filesDir}/vscode/keybindings.json";

  xdg.configFile."zed/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${filesDir}/zed/settings.json";

  xdg.configFile."zed/keymap.json".source =
    config.lib.file.mkOutOfStoreSymlink "${filesDir}/zed/keymap.json";

  xdg.configFile."karabiner/karabiner.json".source =
    config.lib.file.mkOutOfStoreSymlink "${filesDir}/karabiner/karabiner.json";

  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
