{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:

buildNpmPackage (finalAttrs: {
  pname = "codex-acp";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-u3uYZnMVJHGF9IWlXdIAdHWPiGC3ENFIEAaU4Nv0l7M=";
  };

  npmDepsHash = "sha256-MpBjRpOrOE7mGAAZEe1jwxR0XLf7IXsdWhtkAhuREaM=";
  npmBuildScript = "build";

  passthru.updateWithBulkUpdater = true;

  meta = {
    description = "ACP adapter for Codex CLI";
    homepage = "https://github.com/agentclientprotocol/codex-acp";
    changelog = "https://github.com/agentclientprotocol/codex-acp/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "codex-acp";
    platforms = [ "aarch64-darwin" ];
  };
})
