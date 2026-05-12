{ pkgs, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        paging = {
          colorArg = "always";
        };
        pagers = [
          {
            pager = "delta --dark --paging=never";
          }
        ];
      };
    };
  };
}
