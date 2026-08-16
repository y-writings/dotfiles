{
  lib,
  enabledInstallFeatures ? [ ],
  ...
}:
let
  hasInstallFeature = feature: lib.elem feature enabledInstallFeatures;
  aiDevelopmentEnabled = hasInstallFeature "ai-development";
  codexEnabled = hasInstallFeature "codex" || aiDevelopmentEnabled;
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
      "brainfm"
      "cleanshot"
      {
        name = "dbeaver-community";
        # nix-darwin embeds this value in a double-quoted Brewfile string, so
        # passing the script contents directly would leave newlines and quotes
        # unescaped. Execute the script from the Nix store instead.
        postinstall = "/bin/sh ${./homebrew-postinstall/dbeaver-vrapper.sh}";
      }
      "entireio/tap/entire"
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
