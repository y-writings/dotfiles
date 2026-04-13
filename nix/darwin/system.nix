{
  username,
  pkgs,
  ...
}:
{
  system.primaryUser = username;
  system.startup.chime = false;
  security.pam.services.sudo_local.watchIdAuth = true;

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    udev-gothic-nf
  ];

  system.defaults.NSGlobalDomain = {
    ApplePressAndHoldEnabled = false;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
    "com.apple.trackpad.scaling" = 1.5;
  };
  system.defaults.dock.showMissionControlGestureEnabled = false;
  system.defaults.NSGlobalDomain.AppleEnableSwipeNavigateWithScrolls = true;
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # Select the previous input source (^Space) - 60
        "60" = {
          enabled = false;
          value = {
            parameters = [
              32
              49
              262144
            ];
            type = "standard";
          };
        };
        # Select next source in Input menu (^⌥Space) - 61
        "61" = {
          enabled = false;
          value = {
            parameters = [
              32
              49
              786432
            ];
            type = "standard";
          };
        };
        # Application windows (Cmd+J) - 33
        "33" = {
          enabled = true;
          value = {
            parameters = [
              106
              38
              1048576
            ];
            type = "standard";
          };
        };
      };
    };
  };

  system.defaults.dock = {
    tilesize = 24;
    magnification = true;
    largesize = 48;
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 0.5;
    persistent-apps = [
      "/System/Applications/System Settings.app"
      "/Applications/Ghostty.app"
      "/Applications/Arc.app"
    ];

  };

  launchd.user.agents.warpd = {
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
      ProgramArguments = [
        "/etc/profiles/per-user/${username}/bin/warpd"
        "-f"
      ];
    };
  };

  services.jankyborders = {
    enable = true;
    style = "round";
    width = 6.0;
    hidpi = true;
    active_color = "0xc0ff00f2";
    inactive_color = "0xff0080ff";
  };
}
