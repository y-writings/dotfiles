{
  config,
  lib,
  pkgs,
  ...
}:
let
  preferencesDirectory = "${config.home.homeDirectory}/Library/DBeaverData/workspace6/.metadata/.plugins/org.eclipse.core.runtime/.settings";
  preferencesFile = "${preferencesDirectory}/org.jkiss.dbeaver.core.prefs";
in
{
  home.activation.disableDbeaverAutoUpdateCheck = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg preferencesDirectory}

    if ${pkgs.gnugrep}/bin/grep -q '^ui\.auto\.update\.check=' ${lib.escapeShellArg preferencesFile} 2>/dev/null; then
      $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/^ui\.auto\.update\.check=.*/ui.auto.update.check=false/' ${lib.escapeShellArg preferencesFile}
    else
      ${pkgs.coreutils}/bin/printf '%s\n' 'ui.auto.update.check=false' \
        | $DRY_RUN_CMD ${pkgs.coreutils}/bin/tee -a ${lib.escapeShellArg preferencesFile} >/dev/null
    fi
  '';
}
