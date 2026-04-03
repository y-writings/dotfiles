{ pkgs }:
let
  # Fallback wrapper for tools not yet packaged in nixpkgs.
  difitFromGitHub = pkgs.writeShellApplication {
    name = "difit";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      exec ${pkgs.nodejs}/bin/npx --yes difit "$@"
    '';
  };

  # Official prebuilt tarball from upstream warpd release for macOS.
  warpdFromOfficialRelease = pkgs.stdenvNoCC.mkDerivation {
    pname = "warpd";
    version = "1.3.5";

    src = pkgs.fetchurl {
      url = "https://github.com/rvaiya/warpd/releases/download/v1.3.5/warpd-1.3.5-osx.tar.gz";
      hash = "sha256-Sku66zqGTNRbPTvYQb3YfcZ7IJm4YNoYuB77I9KK+ys=";
    };

    dontBuild = true;
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.gnutar ];

    installPhase = ''
      runHook preInstall

      extractDir="$TMPDIR/warpd-extract"
      mkdir -p "$extractDir"
      tar -xzf "$src" -C "$extractDir"

      mkdir -p "$out/bin" "$out/share/man/man1" "$out/share/warpd"
      install -m755 "$extractDir/usr/local/bin/warpd" "$out/bin/warpd"
      install -m644 "$extractDir/usr/local/share/man/man1/warpd.1.gz" "$out/share/man/man1/warpd.1.gz"
      install -m644 "$extractDir/Library/LaunchAgents/com.warpd.warpd.plist" "$out/share/warpd/com.warpd.warpd.plist"

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Modal keyboard driven interface for mouse manipulation";
      homepage = "https://github.com/rvaiya/warpd";
      license = licenses.mit;
      platforms = platforms.darwin;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      mainProgram = "warpd";
    };
  };

  darwinOnlyPackages = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    warpdFromOfficialRelease
  ];
in
[
  difitFromGitHub
]
++ darwinOnlyPackages
