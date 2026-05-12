{ pkgs, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        pagers = [
          {
            pager = "hunk";
          }
        ];
      };
    };
  };
}
