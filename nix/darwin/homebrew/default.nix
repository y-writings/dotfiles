{
  lib,
  pkgs,
  enabledInstallFeatures ? [ ],
  ...
}:
let
  featurePackages = import ./features.nix { inherit lib enabledInstallFeatures; };
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
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    taps = [
      "k1low/tap"
    ];

    inherit (featurePackages) masApps;

    brews = [
      "agent-browser"
      "entire-cli"
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
        postinstall = "/bin/sh ${../homebrew-postinstall/dbeaver-vrapper.sh} ${vrapperUpdateSite}";
      }
      "grok-bot"
      "grok-build"
      "homerow"
      "karabiner-elements"
      "notion"
      "obsidian"
      "orbstack"
      "postman"
      "raycast"
      "slack"
      "t3-code"
      "zed"
    ]
    ++ featurePackages.casks;
  };
}
