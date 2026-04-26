{ paths, ... }:
{
  programs.ghostty = {
    enable = true;
    package = null;
    enableZshIntegration = true;
    settings = {
      keybind = [
        "shift+enter=text:\x1b\r"
        "cmd+k>o=toggle_background_opacity"
      ];
      "background-opacity" = 0.5;
      "macos-option-as-alt" = "left";
      "font-family" = [
        "Cascadia Code NF"
        "UDEV Gothic 35NFLG"
      ];
      "font-feature" = "calt,liga";
      theme = "TokyoNight Night";
      working-directory = paths.workspacePath;
    };
  };
}
