{ userConfigRoot }:
let
  helpers = import ./helper/user-config.nix { inherit builtins; };
  userConfig = helpers.loadUserConfig userConfigRoot;

  home = helpers.requiredString {
    config = userConfig;
    fieldName = "home";
  };
  dotfilesRoot = helpers.requiredString {
    config = userConfig;
    fieldName = "dotfilesRoot";
  };
  username = helpers.requiredString {
    config = userConfig;
    fieldName = "username";
  };

  sanitize = import ./helper/sanitize.nix { inherit builtins; };

  rawEnabledInstallFeatures = userConfig.enabledInstallFeatures or [ ];
  allowedInstallFeatures = [
    "productivity"
    "ai-development"
    "codex"
    "masapps"
  ];
  enabledInstallFeatures = sanitize.sanitizeStringListAllowlist {
    value = rawEnabledInstallFeatures;
    allowlist = allowedInstallFeatures;
    fieldName = "enabledInstallFeatures";
  };

  rawSecrets = userConfig.secrets or { };
  allowedSecretNames = [ "EXA_API_KEY" ];
  secrets = sanitize.sanitizeStringAttrsAllowlist {
    value = rawSecrets;
    allowlist = allowedSecretNames;
    fieldName = "secrets";
  };

in
{
  inherit
    username
    dotfilesRoot
    enabledInstallFeatures
    secrets
    ;

  homeDir = home;
  gitIdentity = userConfig.gitIdentity;
}
