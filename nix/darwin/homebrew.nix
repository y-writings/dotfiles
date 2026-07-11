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
    formulae = [
      "k1low/tap/mo"
      "modem-dev/tap/hunk"
    ];
    casks = [ "entireio/tap/entire" ];
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    taps = [
      "entireio/tap"
      "k1low/tap"
      "modem-dev/tap"
    ];

    masApps =
      { }
      // lib.optionalAttrs (hasInstallFeature "masapps") {
        "Kindle" = 302584613;
        "Klack" = 6446206067;
      };

    brews = [
      "agent-browser"
      "k1low/tap/mo"
      "modem-dev/tap/hunk"
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
      "dbeaver-community"
      "entireio/tap/entire"
      "ghostty@tip"
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
