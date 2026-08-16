{
  buildNpmPackage,
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  pnpm_11,
  pnpmConfigHook,
}:

let
  pnpm = pnpm_11;
in
buildNpmPackage (finalAttrs: {
  pname = "difit";
  version = "5.0.11";

  src = fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    tag = "v${finalAttrs.version}";
    hash = "sha256-0qef7IhDOEPwLXhXe+vU52c505sH03xRbjUQUqgmyQ4=";
  };

  npmDeps = null;
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-PLV82tBaOX7hDxRcV2owulK4EslaEcJGM1N1uuEQei8=";
  };

  nativeBuildInputs = [ pnpm ];
  npmConfigHook = pnpmConfigHook;
  npmBuildScript = "build";

  # npm pack otherwise runs upstream's prepare hook, which invokes lefthook.
  npmPackFlags = [ "--ignore-scripts" ];

  # npm cannot safely prune a pnpm workspace after the frozen install.
  dontNpmPrune = true;

  # Replace build-time dev dependencies with the exact production graph before npmInstallHook copies the package.
  postBuild = ''
    rm -rf node_modules packages/vscode/node_modules
    pnpm install --prod --offline --frozen-lockfile --ignore-scripts
  '';

  postInstall = ''
    rm "$out/lib/node_modules/difit/node_modules/.pnpm/node_modules/difit-vscode"
  '';

  meta = {
    description = "GitHub-like local diff viewer";
    homepage = "https://github.com/yoshiko-pg/difit";
    changelog = "https://github.com/yoshiko-pg/difit/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "difit";
    platforms = [ "aarch64-darwin" ];
  };
})
