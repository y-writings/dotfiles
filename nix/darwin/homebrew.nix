{
  lib,
  pkgs,
  enabledInstallFeatures ? [ ],
  ...
}:
let
  hasInstallFeature = feature: lib.elem feature enabledInstallFeatures;
  aiDevelopmentEnabled = hasInstallFeature "ai-development";
  codexEnabled = hasInstallFeature "codex" || aiDevelopmentEnabled;
  vrapperVersion = "0.74.0";
  vrapperUpdateSite =
    pkgs.runCommand "vrapper-update-site-${vrapperVersion}"
      {
        src = pkgs.fetchurl {
          url = "https://github.com/vrapper/vrapper/releases/download/${vrapperVersion}/vrapper_${vrapperVersion}_20181124.zip";
          hash = "sha256-q4IZhikiVaIStrUAlxd3dCPkpDFNrCdoyQ5MFLTvmaY=";
        };
        nativeBuildInputs = [ pkgs.unzip ];
      }
      ''
        mkdir -p "$out"
        unzip -q "$src" -d "$out"
      '';
in
{
  nix-homebrew.trust = {
    formulae = [ "k1low/tap/mo" ];
    casks = [ "entireio/tap/entire" ];
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    taps = [
      "entireio/tap"
      "k1low/tap"
    ];

    masApps =
      { }
      // lib.optionalAttrs (hasInstallFeature "masapps") {
        "Kindle" = 302584613;
        "Klack" = 6446206067;
      };

    brews = [
      "agent-browser"
      "hunk"
      "k1low/tap/mo"
    ];

    casks = [
      # browser
      "arc"
      "google-chrome"
      "thebrowsercompany-dia"
      # editor
      "visual-studio-code"
      # others
      "1password"
      "1password-cli"
      "amical"
      "antigravity-cli"
      "brainfm"
      "cleanshot"
      {
        name = "dbeaver-community";
        # nix-darwin embeds this value in a double-quoted Brewfile string, so
        # passing the script contents directly would leave newlines and quotes
        # unescaped. Execute the script from the Nix store instead.
        postinstall = "/bin/sh ${./homebrew-postinstall/dbeaver-vrapper.sh} ${vrapperUpdateSite}";
      }
      "entireio/tap/entire"
      "grok-bot"
      "grok-build"
      "homerow"
      "jordanbaird-ice"
      "karabiner-elements"
      "notion"
      "obsidian"
      "orbstack"
      "postman"
      "raycast"
      "slack"
      "zed"
    ]
    ++ lib.optionals (hasInstallFeature "productivity") [
      "rize"
    ]
    ++ lib.optionals aiDevelopmentEnabled [
      "ollama-app"
    ]
    ++ lib.optionals codexEnabled [
      "codex-app"
    ];
  };
}
