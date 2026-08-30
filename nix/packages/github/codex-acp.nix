{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:

buildNpmPackage (finalAttrs: {
  pname = "codex-acp";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-oOByalquD4I4s+3JafMDYlQ3dGN1TAfq3sy6owSsv6M=";
  };

  npmDepsHash = "sha256-5dk7J0nDg4YWpiSnnY11JPWKgMgJn1Wi0KGAyhdc1Fk=";
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
