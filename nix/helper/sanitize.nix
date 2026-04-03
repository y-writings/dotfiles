{ builtins }:
let
  sanitizeStringListAllowlist =
    {
      value,
      allowlist,
      fieldName,
    }:
    if builtins.isList value then
      builtins.filter (item: builtins.isString item && builtins.elem item allowlist) value
    else
      throw "${fieldName} in ~/.config/nix/user.toml must be an array (list)";

  sanitizeStringAttrsAllowlist =
    {
      value,
      allowlist,
      fieldName,
    }:
    if builtins.isAttrs value then
      builtins.listToAttrs (
        builtins.filter (entry: builtins.elem entry.name allowlist && builtins.isString entry.value) (
          builtins.map (name: {
            inherit name;
            value = value.${name};
          }) (builtins.attrNames value)
        )
      )
    else
      throw "${fieldName} in ~/.config/nix/user.toml must be a table (attrset)";
in
{
  inherit sanitizeStringListAllowlist sanitizeStringAttrsAllowlist;
}
