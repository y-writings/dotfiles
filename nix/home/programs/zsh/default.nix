{
  pkgs,
  config,
  inputs,
  paths,
  secrets,
  ...
}:
{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 20000;
      extended = true;
    };

    shellAliases = {
      ".." = "cd ../";
      ll = "eza -F -lgh";
      la = "eza -F -lgha";
      llg = "eza -F -lgh --git";
      lag = "eza -F -lgha --git";
      dr = "cd ${paths.ghqRootPath}";
      dw = "cd $vscodeWorkspace";
      dc = "COMPOSE_BAKE=true docker compose";
      lg = "lazygit";
      ld = "lazydocker";
      nr = "ni run";
      mr = "mise run";
      rp = "realpath";
      sg = "ast-grep";
      pbc = "pbcopy";
      pbp = "pbpaste";

      # OP_RUN_NO_MASKING: MASKING状態だとopencodeのレイアウトが崩れるため設定
      oc = "OP_RUN_NO_MASKING=true op run -- opencode";
      devcontainer = "op run -- command devcontainer";
    };

    sessionVariables = {
      ZSH_DISABLE_COMPFIX = "true";
      HISTTIMEFORMAT = "%Y-%m-%d %H:%M:%S ";
      EDITOR = "${pkgs.neovim}/bin/nvim";
      VISUAL = "${pkgs.neovim}/bin/nvim";
    }
    // (if builtins.hasAttr "EXA_API_KEY" secrets then { EXA_API_KEY = secrets.EXA_API_KEY; } else { });

    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
      {
        name = "ni";
        src = inputs.ni-zsh;
        file = "ni.zsh";
      }
    ];

    initContent = ''
      # Source utility functions (gr, gw, dlog, etc.)
      source ${./functions.zsh}

      # Source custom ZLE widgets and registrations
      source ${./zle-widgets.zsh}
    '';
  };

  # Path configuration
  home.sessionVariables =
    if builtins.hasAttr "EXA_API_KEY" secrets then { EXA_API_KEY = secrets.EXA_API_KEY; } else { };

  home.sessionPath = [
    "${paths.workspacePath}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "/opt/homebrew/bin"
  ];
}
