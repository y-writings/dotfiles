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
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    taps = [ ];

    masApps =
      { }
      // lib.optionalAttrs (hasInstallFeature "masapps") {
        "Kindle" = 302584613;
        "Klack" = 6446206067;
      };

    brews = [
      "agent-browser"
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
      "dbeaver-community"
      "ghostty@tip"
      "homerow"
      "jordanbaird-ice"
      "karabiner-elements"
      "obsidian"
      "orbstack"
      "postman"
      "raycast"
      "slack"
      "zed"
    ]
    ++ lib.optionals (hasInstallFeature "productivity") [
      "cleanshot"
      "rize"
    ]
    ++ lib.optionals aiDevelopmentEnabled [
      "ollama-app"
    ]
    ++ lib.optionals codexEnabled [
      "codex"
    ];
  };
}
