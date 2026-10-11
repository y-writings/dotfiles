{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:

buildNpmPackage (finalAttrs: {
  pname = "codex-acp";
  version = "2.2.2";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9qIKaDZJ80PVO7/qBfbOE7un2Ukk92bZVrIaHG/K8P8=";
  };

  npmDepsHash = "sha256-4wXnQnPEUp0DtNphXBS5/WQkgErRD631xOB0KqDXf4U=";
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
