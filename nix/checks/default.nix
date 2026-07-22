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
            from="$2"
            to="$3"
            script="$TMPDIR/retime.sh"
            ${pkgs.gnused}/bin/sed \
              -e "s#{{.SelectedCommitRange.From}}#$from#g" \
              -e "s#{{.SelectedCommitRange.To}}#$to#g" \
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

        invalid_repo="$TMPDIR/invalid"
        make_repo "$invalid_repo"
        invalid_branch=$(git -C "$invalid_repo" branch --show-current)
        git -C "$invalid_repo" branch topic HEAD~3
        git -C "$invalid_repo" switch -q topic
        git -C "$invalid_repo" commit --allow-empty -qm topic
        invalid_from=$(git -C "$invalid_repo" rev-parse HEAD)
        git -C "$invalid_repo" switch -q "$invalid_branch"
        invalid_to=$(git -C "$invalid_repo" rev-parse HEAD~1)
        invalid_tip=$(git -C "$invalid_repo" rev-parse HEAD)
        if run_command "$invalid_repo" "$invalid_from" "$invalid_to"; then
          printf '%s\n' 'accepted a range whose lower endpoint is outside the current branch' >&2
          exit 1
        fi
        test "$(git -C "$invalid_repo" rev-parse HEAD)" = "$invalid_tip"

        unreachable_repo="$TMPDIR/unreachable"
        make_repo "$unreachable_repo"
        unreachable_branch=$(git -C "$unreachable_repo" branch --show-current)
        git -C "$unreachable_repo" branch topic HEAD~3
        git -C "$unreachable_repo" switch -q topic
        git -C "$unreachable_repo" commit --allow-empty -qm topic
        unreachable_from=$(git -C "$unreachable_repo" rev-parse HEAD~1)
        unreachable_to=$(git -C "$unreachable_repo" rev-parse HEAD)
        git -C "$unreachable_repo" switch -q "$unreachable_branch"
        unreachable_tip=$(git -C "$unreachable_repo" rev-parse HEAD)
        if run_command "$unreachable_repo" "$unreachable_from" "$unreachable_to"; then
          printf '%s\n' 'accepted a range outside the current branch' >&2
          exit 1
        fi
        test "$(git -C "$unreachable_repo" rev-parse HEAD)" = "$unreachable_tip"

        detached_repo="$TMPDIR/detached"
        make_repo "$detached_repo"
        git -C "$detached_repo" switch --detach -q HEAD~1
        detached=$(git -C "$detached_repo" rev-parse HEAD)
        if run_command "$detached_repo" "$detached" "$detached"; then
          printf '%s\n' 'accepted a detached HEAD' >&2
          exit 1
        fi
        test "$(git -C "$detached_repo" rev-parse HEAD)" = "$detached"

        dirty_repo="$TMPDIR/dirty"
        make_repo "$dirty_repo"
        dirty_branch=$(git -C "$dirty_repo" branch --show-current)
        printf '%s\n' clean > "$dirty_repo/tracked"
        git -C "$dirty_repo" add tracked
        git -C "$dirty_repo" commit -qm tracked
        dirty_tip=$(git -C "$dirty_repo" rev-parse HEAD)
        dirty_backup_ref="refs/lazygit/retime-original/keep/refs/heads/$dirty_branch"
        dirty_last_ref="refs/lazygit/retime-last/refs/heads/$dirty_branch"
        git -C "$dirty_repo" update-ref "$dirty_backup_ref" "$dirty_tip"
        git -C "$dirty_repo" update-ref "$dirty_last_ref" "$dirty_tip"
        printf '%s\n' modified > "$dirty_repo/tracked"
        dirty_selected=$(git -C "$dirty_repo" rev-parse HEAD~2)
        if run_command "$dirty_repo" "$dirty_selected" "$dirty_selected"; then
          printf '%s\n' accepted a dirty worktree >&2
          exit 1
        fi
        test "$(git -C "$dirty_repo" rev-parse "$dirty_backup_ref")" = "$dirty_tip"
        test "$(git -C "$dirty_repo" rev-parse "$dirty_last_ref")" = "$dirty_tip"

        single_repo="$TMPDIR/single"
        make_repo "$single_repo"
        old_tip=$(git -C "$single_repo" rev-parse HEAD)
        git -C "$single_repo" update-ref refs/original/refs/heads/unrelated "$old_tip"
        selected=$(git -C "$single_repo" rev-parse HEAD~2)
        run_command "$single_repo" "$selected" "$selected"
          selected_author=$(git -C "$single_repo" show -s --format=%aI HEAD~2)
          selected_committer=$(git -C "$single_repo" show -s --format=%cI HEAD~2)
          test "$selected_author" = "$selected_committer"
          test "$selected_author" != '2024-01-02T00:00:00Z'
          case "$selected_author" in *Z) ;; *) exit 1 ;; esac
          assert_date "$single_repo" HEAD~3 '2024-01-01T00:00:00Z' '2024-01-01T00:00:00Z'
        assert_date "$single_repo" HEAD~1 '2024-01-03T00:00:00Z' '2024-01-03T00:00:00Z'
        assert_date "$single_repo" HEAD '2024-01-04T00:00:00Z' '2024-01-04T00:00:00Z'
        test "$(git -C "$single_repo" rev-parse HEAD)" != "$old_tip"
        test "$(git -C "$single_repo" rev-parse refs/original/refs/heads/unrelated)" = "$old_tip"
        if git -C "$single_repo" rev-parse --verify "refs/original/refs/heads/$(git -C "$single_repo" branch --show-current)" >/dev/null 2>&1; then
          printf '%s\n' 'created a default filter-branch backup ref' >&2
          exit 1
        fi
        backup_ref="refs/lazygit/retime-last/refs/heads/$(git -C "$single_repo" branch --show-current)"
        test "$(git -C "$single_repo" rev-parse "$backup_ref")" = "$old_tip"

          root_repo="$TMPDIR/root"
          make_repo "$root_repo"
          root_from=$(git -C "$root_repo" rev-parse HEAD~3)
          root_to=$(git -C "$root_repo" rev-parse HEAD~2)
          run_command "$root_repo" "$root_from" "$root_to"
          root_author=$(git -C "$root_repo" show -s --format=%aI HEAD~3)
          root_committer=$(git -C "$root_repo" show -s --format=%cI HEAD~3)
          test "$root_author" = "$root_committer"
          test "$root_author" != '2024-01-01T00:00:00Z'
          assert_date "$root_repo" HEAD~2 "$root_author" "$root_committer"
          assert_date "$root_repo" HEAD~1 '2024-01-03T00:00:00Z' '2024-01-03T00:00:00Z'
          assert_date "$root_repo" HEAD '2024-01-04T00:00:00Z' '2024-01-04T00:00:00Z'

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
