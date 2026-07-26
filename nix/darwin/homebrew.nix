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
        postinstall = ''
          dbeaver_executable="/Applications/DBeaver.app/Contents/MacOS/dbeaver"
          dbeaver_features="/Applications/DBeaver.app/Contents/Eclipse/features"
          vrapper_update_site="https://vrapper.sourceforge.net/update-site/stable/"
          vrapper_feature="net.sourceforge.vrapper.feature.group"

          if /usr/bin/pgrep -f '[D]Beaver.app/Contents/MacOS/dbeaver' >/dev/null; then
            echo "DBeaver is running. Quit DBeaver, then run the nix-darwin rebuild again." >&2
            exit 1
          fi

          if [ ! -x "$dbeaver_executable" ]; then
            echo "DBeaver p2 launcher was not found at $dbeaver_executable." >&2
            exit 1
          fi

          if /usr/bin/find "$dbeaver_features" -maxdepth 1 -name 'net.sourceforge.vrapper.feature_*' -print -quit \
            | /usr/bin/grep -q .; then
            echo "Vrapper is already installed; skipping."
            exit 0
          fi

          "$dbeaver_executable" \
            -nosplash \
            -application org.eclipse.equinox.p2.director \
            -repository "$vrapper_update_site" \
            -installIU "$vrapper_feature" \
            -trustedAuthorities "$vrapper_update_site"
        '';
      }
      "entireio/tap/entire"
      "ghostty@tip"
      "homerow"
      "jordanbaird-ice"
      "karabiner-elements"
      "notion"
      "obsidian"
      "orbstack"
      "postman"
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
