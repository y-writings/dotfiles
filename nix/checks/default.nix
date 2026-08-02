{
  inputs,
  hostSystem,
  homeModule,
  mkDarwinSystem,
}:
let
  username = "public";
  homeDir = "/Users/${username}";
  workspacePath = "${homeDir}/workspace";
  ghqRootPath = "${workspacePath}/repos";
  dotfilesRoot = toString ../..;
  paths = {
    inherit
      homeDir
      dotfilesRoot
      workspacePath
      ghqRootPath
      ;
  };

  pkgs = import inputs.nixpkgs {
    system = hostSystem;
    config.allowUnfree = true;
  };

  homeArgs = {
    inherit
      inputs
      paths
      ;
    gitIdentity = {
      name = "Public User";
      email = "public@example.com";
    };
    secrets = { };
  };

  baseSystemArgs = {
    system = hostSystem;
    inherit
      username
      paths
      ;
    gitIdentity = {
      name = "Public User";
      email = "public@example.com";
    };
    enabledInstallFeatures = [ ];
    secrets = { };
  };

  overlayMarker = "private-overlay-marker";

  homeConfiguration =
    extraModules:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = homeArgs;
      modules = [
        homeModule
        {
          home = {
            inherit username;
            homeDirectory = paths.homeDir;
            stateVersion = "25.11";
          };
        }
      ]
      ++ extraModules;
    };

  lazygitSettings = (import ../home/programs/lazygit { inherit pkgs; }).programs.lazygit.settings;
in
{
  exported-home-base = (homeConfiguration [ ]).activationPackage;

  git-wt-integration =
    let
      configuration = homeConfiguration [ ];
    in
    assert configuration.config.programs.git.settings.wt.basedir == ".worktrees";
    assert pkgs.lib.hasPrefix "eval \"$(git wt --init zsh)\""
      configuration.config.programs.zsh.initContent;
    pkgs.runCommand "git-wt-integration-check" { } ''
      touch "$out"
    '';

  lazygit-retime-commits =
    let
      retimeCommand = builtins.head lazygitSettings.customCommands;
      command = retimeCommand.command;
      commandTemplate = builtins.toFile "lazygit-retime-command.sh" command;
    in
    assert pkgs.lib.hasInfix "以降のコミットID" (builtins.head retimeCommand.prompts).body;
    assert pkgs.lib.hasInfix "{{.SelectedCommit.Hash}}" command;
    assert !pkgs.lib.hasInfix "SelectedCommitRange" command;
    assert !pkgs.lib.hasInfix "filter-branch" command;
    assert !pkgs.lib.hasInfix "refs/lazygit" command;
    pkgs.runCommand "lazygit-retime-commits-check"
      {
        nativeBuildInputs = [
          pkgs.bash
          pkgs.git
        ];
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"

        make_repo() {
            repo="$1"
            git init -q "$repo"
            git -C "$repo" config user.name Test
            git -C "$repo" config user.email test@example.com
            GIT_AUTHOR_DATE='2024-01-01T00:00:00Z' GIT_COMMITTER_DATE='2024-01-01T00:00:00Z' git -C "$repo" commit --allow-empty -qm one
            GIT_AUTHOR_DATE='2024-01-02T00:00:00Z' GIT_COMMITTER_DATE='2024-01-02T00:00:00Z' git -C "$repo" commit --allow-empty -qm two
            GIT_AUTHOR_DATE='2024-01-03T00:00:00Z' GIT_COMMITTER_DATE='2024-01-03T00:00:00Z' git -C "$repo" commit --allow-empty -qm three
            GIT_AUTHOR_DATE='2024-01-04T00:00:00Z' GIT_COMMITTER_DATE='2024-01-04T00:00:00Z' git -C "$repo" commit --allow-empty -qm four
          }

          run_command() {
            repo="$1"
            selected="$2"
            script="$TMPDIR/retime.sh"
            ${pkgs.gnused}/bin/sed \
              -e "s#{{.SelectedCommit.Hash}}#$selected#g" \
              ${commandTemplate} > "$script"
            chmod +x "$script"
            (
              cd "$repo"
              ${pkgs.bash}/bin/bash "$script"
            )
          }

        assert_date() {
          repo="$1"
          revision="$2"
          expected_author="$3"
          expected_committer="$4"
          test "$(git -C "$repo" show -s --format=%aI "$revision")" = "$expected_author"
          test "$(git -C "$repo" show -s --format=%cI "$revision")" = "$expected_committer"
        }

        unreachable_repo="$TMPDIR/unreachable"
        make_repo "$unreachable_repo"
        unreachable_branch=$(git -C "$unreachable_repo" branch --show-current)
        git -C "$unreachable_repo" branch topic HEAD~3
        git -C "$unreachable_repo" switch -q topic
        git -C "$unreachable_repo" commit --allow-empty -qm topic
        unreachable_selected=$(git -C "$unreachable_repo" rev-parse HEAD)
        git -C "$unreachable_repo" switch -q "$unreachable_branch"
        unreachable_tip=$(git -C "$unreachable_repo" rev-parse HEAD)
        if run_command "$unreachable_repo" "$unreachable_selected"; then
          printf '%s\n' 'accepted a commit outside the current branch' >&2
          exit 1
        fi
        test "$(git -C "$unreachable_repo" rev-parse HEAD)" = "$unreachable_tip"

        dirty_repo="$TMPDIR/dirty"
        make_repo "$dirty_repo"
        printf '%s\n' clean > "$dirty_repo/tracked"
        git -C "$dirty_repo" add tracked
        git -C "$dirty_repo" commit -qm tracked
        dirty_tip=$(git -C "$dirty_repo" rev-parse HEAD)
        printf '%s\n' modified > "$dirty_repo/tracked"
        dirty_selected=$(git -C "$dirty_repo" rev-parse HEAD~2)
        if run_command "$dirty_repo" "$dirty_selected"; then
          printf '%s\n' accepted a dirty worktree >&2
          exit 1
        fi
        test "$(git -C "$dirty_repo" rev-parse HEAD)" = "$dirty_tip"

        retime_repo="$TMPDIR/retime"
        make_repo "$retime_repo"
        selected=$(git -C "$retime_repo" rev-parse HEAD~2)
        older=$(git -C "$retime_repo" rev-parse "$selected^")
        old_tip=$(git -C "$retime_repo" rev-parse HEAD)
        run_command "$retime_repo" "$selected"

        test "$(git -C "$retime_repo" rev-parse HEAD~3)" = "$older"
        assert_date "$retime_repo" HEAD~3 '2024-01-01T00:00:00Z' '2024-01-01T00:00:00Z'
        test "$(git -C "$retime_repo" rev-parse HEAD)" != "$old_tip"

        rewrite_date=$(git -C "$retime_repo" show -s --format=%aI HEAD~2)
        test "$rewrite_date" != '2024-01-02T00:00:00Z'
        assert_date "$retime_repo" HEAD~2 "$rewrite_date" "$rewrite_date"
        assert_date "$retime_repo" HEAD~1 "$rewrite_date" "$rewrite_date"
        assert_date "$retime_repo" HEAD "$rewrite_date" "$rewrite_date"

        touch "$out"
      '';

  exported-home-overlay =
    (homeConfiguration [
      {
        xdg.configFile."overlay-marker".text = overlayMarker;
      }
    ]).activationPackage;

  exported-darwin-base = (mkDarwinSystem baseSystemArgs).config.system.build.toplevel;

  exported-darwin-overlay =
    let
      systemWithOverlays = mkDarwinSystem (
        baseSystemArgs
        // {
          extraHomeModules = [
            (
              {
                lib,
                ...
              }:
              {
                xdg.configFile."overlay-marker".text = overlayMarker;
                programs.git.settings.alias.graph = lib.mkForce overlayMarker;
              }
            )
          ];
          extraDarwinModules = [
            (
              {
                lib,
                ...
              }:
              {
                environment.etc."overlay-marker".text = overlayMarker;
                nix.settings.extra-substituters = lib.mkAfter [ "https://overlay.example.invalid" ];
              }
            )
          ];
        }
      );
    in
    pkgs.runCommand "exported-darwin-overlay-check" { } ''
      test -f ${systemWithOverlays.config.system.build.toplevel}/etc/overlay-marker
      test "$(cat ${systemWithOverlays.config.system.build.toplevel}/etc/overlay-marker)" = '${overlayMarker}'
      test -f ${
        systemWithOverlays.config.home-manager.users.${username}.xdg.configFile."overlay-marker".source
      }
      test "$(cat ${
        systemWithOverlays.config.home-manager.users.${username}.xdg.configFile."overlay-marker".source
      })" = '${overlayMarker}'
      test '${
        systemWithOverlays.config.home-manager.users.${username}.programs.git.settings.alias.graph
      }' = '${overlayMarker}'
      test '${builtins.toJSON systemWithOverlays.config.nix.settings.extra-substituters}' = '["https://cache.nixos.org/","https://yazi.cachix.org","https://overlay.example.invalid"]'
      touch "$out"
    '';
}
