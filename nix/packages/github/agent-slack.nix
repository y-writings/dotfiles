{
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "agent-slack";
  version = "0.9.3";

  src = fetchurl {
    url = "https://github.com/stablyai/agent-slack/releases/download/v${finalAttrs.version}/agent-slack-darwin-arm64";
    hash = "sha256-ISvecKk6btX0kRyOc4jLH1a1HuCFABa8K9VbdByiBZY=";
  };

  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/agent-slack"

    runHook postInstall
  '';

  meta = {
    description = "Slack automation CLI for AI agents";
    homepage = "https://github.com/stablyai/agent-slack";
    changelog = "https://github.com/stablyai/agent-slack/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "agent-slack";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
