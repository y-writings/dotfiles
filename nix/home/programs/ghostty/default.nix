{
  config,
  paths,
  pkgs,
  ...
}:
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    enableZshIntegration = true;
    settings = {
      "auto-update" = "off";
      keybind = [
        "shift+enter=text:\x1b\r"
        "cmd+shift+o=write_screen_file:copy"
        "chain=text:\\x15gscroll\\r"
        "cmd+k>o=toggle_background_opacity"
        "cmd+k>h=new_split:left"
        "cmd+k>l=new_split:right"
        "cmd+k>j=new_split:down"
        "cmd+k>k=new_split:up"
        "alt+h=goto_split:left"
        "alt+l=goto_split:right"
        "alt+j=goto_split:down"
        "alt+k=goto_split:up"
        "ctrl+h=previous_tab"
        "ctrl+l=next_tab"
        "ctrl+shift+x=activate_key_table:copy"

        "copy/escape=deactivate_key_table"
        "copy/q=deactivate_key_table"

        "copy/k=scroll_page_lines:-1"
        "copy/j=scroll_page_lines:1"
        "copy/ctrl+u=scroll_page_fractional:-0.5"
        "copy/ctrl+d=scroll_page_fractional:0.5"

        "copy/y=copy_to_clipboard"
        "chain=deactivate_key_table"
      ];
      "background-opacity" = 0.5;
      "macos-option-as-alt" = "left";
      "font-family" = [
        "Monaspace Neon Frozen"
        "UDEV Gothic 35NFLG"
      ];
      "font-feature" = "calt,liga";
      theme = "TokyoNight Night";
      working-directory = paths.workspacePath;
    };
  };

  # SSH login keeps TERM=xterm-ghostty and does not forward TERMINFO.
  # Apple's /bin/zsh looks the terminal up while sourcing nix-darwin's
  # set-environment and Home Manager's hm-session-vars.sh, before
  # TERMINFO_DIRS exists. ~/.terminfo is on ncurses' default search path.
  # ghostty-bin.terminfo is the app bundle's database (hex layout), which
  # both Apple ncurses and Nix ncurses on Darwin can read.
  home.file.".terminfo".source = "${config.programs.ghostty.package.terminfo}/share/terminfo";
}
