{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:

buildNpmPackage (finalAttrs: {
  pname = "codex-acp";
  version = "1.6.2";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QNQ9x4CEO6xzKDd1vggBbntnGLjI1TBmg5ydCWM3T7k=";
  };

  npmDepsHash = "sha256-uK03isdvl9tpYDF1sapHjmPdhtLGbdjE3cDU/qFa5G0=";
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
