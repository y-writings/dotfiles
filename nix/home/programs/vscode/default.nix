{ pkgs, inputs, ... }:
let
  vscodeExts =
    inputs.vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.vscode-marketplace;
in
{
  programs.vscode = {
    enable = true;

    profiles.default.extensions =
      let
        bundledExtensions = with pkgs.vscode-extensions; [
          biomejs.biome
          bradlc.vscode-tailwindcss
          christian-kohler.path-intellisense
          codezombiech.gitignore
          dbaeumer.vscode-eslint
          donjayamanne.githistory
          eamodio.gitlens
          editorconfig.editorconfig
          esbenp.prettier-vscode
          formulahendry.auto-rename-tag
          github.vscode-pull-request-github
          golang.go
          gruntfuggly.todo-tree
          hashicorp.terraform
          jnoortheen.nix-ide
          mechatroner.rainbow-csv
          mhutchie.git-graph
          pkief.material-product-icons
          redhat.vscode-yaml
          streetsidesoftware.code-spell-checker
          styled-components.vscode-styled-components
          timonwong.shellcheck
          vscode-icons-team.vscode-icons
          vscodevim.vim
          yzhang.markdown-all-in-one
        ];

        vscodeExtsExtensions = [
          vscodeExts.ziyasal.vscode-open-in-github
          vscodeExts.aprilandjan.ascii-tree-generator
          vscodeExts.mylesmurphy.prettify-ts
          vscodeExts.ryuta46.multi-command
          vscodeExts."42crunch".vscode-openapi
          vscodeExts.csstools.postcss
          vscodeExts.ezforo.copy-relative-path-and-line-numbers
          vscodeExts.be5invis.vscode-custom-css
          vscodeExts.jackiotyu.git-worktree-manager
          vscodeExts.piotrpalarz.unpin-all-editors
          vscodeExts.tombi-toml.tombi
        ];
      in
      bundledExtensions ++ vscodeExtsExtensions;
  };
}
