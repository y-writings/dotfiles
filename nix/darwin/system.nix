{
  config,
  username,
  pkgs,
  ...
}:
{
  system.primaryUser = username;
  system.startup.chime = false;
  security.pam.services.sudo_local.watchIdAuth = true;

  fonts.packages = with pkgs; [
    maple-mono.truetype
    monaspace
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
        # Application windows (Cmd+Down Arrow) - 33
        "33" = {
          enabled = true;
          value = {
            parameters = [
              65535
              125
              1048576
            ];
            type = "standard";
          };
        };
        # Disabled because CleanShot X handles screenshots: save picture of screen as a file (Shift+Cmd+3) - 28
        "28" = {
          enabled = false;
          value = {
            parameters = [
              51
              20
              1179648
            ];
            type = "standard";
          };
        };
        # Disabled because CleanShot X handles screenshots: copy picture of screen to the clipboard (Ctrl+Shift+Cmd+3) - 29
        "29" = {
          enabled = false;
          value = {
            parameters = [
              51
              20
              1441792
            ];
            type = "standard";
          };
        };
        # Disabled because CleanShot X handles screenshots: save picture of selected area as a file (Shift+Cmd+4) - 30
        "30" = {
          enabled = false;
          value = {
            parameters = [
              52
              21
              1179648
            ];
            type = "standard";
          };
        };
        # Disabled because CleanShot X handles screenshots: copy picture of selected area to the clipboard (Ctrl+Shift+Cmd+4) - 31
        "31" = {
          enabled = false;
          value = {
            parameters = [
              52
              21
              1441792
            ];
            type = "standard";
          };
        };
        # Disabled because CleanShot X handles screenshots: screenshot and recording options (Shift+Cmd+5) - 184
        "184" = {
          enabled = false;
          value = {
            parameters = [
              53
              23
              1179648
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
      "${config.users.users.${username}.home}/Applications/Home Manager Apps/Ghostty.app"
      "/Applications/Arc.app"
      "/Applications/Ice.app"
    ];

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
