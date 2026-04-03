{ builtins }:
let
  userConfigPath = userConfigRoot: builtins.toPath "${toString userConfigRoot}/user.toml";

  loadUserConfig =
    userConfigRoot:
    let
      configPath = userConfigPath userConfigRoot;
    in
    if builtins.pathExists configPath then
      fromTOML (builtins.readFile configPath)
    else
      throw "user.toml not found at ${toString configPath}; pass --override-input user-config path:$HOME/.config/nix";

  requiredString =
    {
      config,
      fieldName,
    }:
    if !(builtins.hasAttr fieldName config) then
      throw "${fieldName} is required in ~/.config/nix/user.toml"
    else
      let
        value = config.${fieldName};
      in
      if builtins.isString value && value != "" then
        value
      else
        throw "${fieldName} in ~/.config/nix/user.toml must be a non-empty string";
in
{
  inherit loadUserConfig requiredString;
}
