{ lib, enabledInstallFeatures }:
let
  hasInstallFeature = feature: lib.elem feature enabledInstallFeatures;
  aiDevelopmentEnabled = hasInstallFeature "ai-development";
  codexEnabled = hasInstallFeature "codex" || aiDevelopmentEnabled;
in
{
  casks =
    lib.optional (hasInstallFeature "productivity") "rize"
    ++ lib.optional aiDevelopmentEnabled "ollama-app"
    ++ lib.optional codexEnabled "codex-app"
    ++ lib.optional (hasInstallFeature "lm-studio") "lm-studio"
    ++ lib.optional (hasInstallFeature "tailscale") "tailscale-app";

  masApps = lib.optionalAttrs (hasInstallFeature "masapps") {
    "Kindle" = 302584613;
    "Klack" = 6446206067;
  };
}
