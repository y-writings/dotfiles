# y-writings' personal dotfiles

macOS (`aarch64-darwin`) を Nix + nix-darwin + Home Manager で
セットアップするための dotfiles です。

## Initial Setup

`sudo` 実行権限と `git`, `curl` がある状態で以下を実行します。

```bash
curl -fsSL -o bootstrap.sh \
  https://raw.githubusercontent.com/y-writings/dotfiles/main/script/bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh
```

Xcode Command Line Tools、Determinate Nix、`user.toml`、nix-darwin 環境まで初期セットアップします。

## Maintenance

初回実行後は `mise` で rebuild します。

```bash
mise run rebuild
```

その他のタスクは `mise tasks` で確認できます。

### DBeaver / Vrapper

DBeaver Community は Homebrew cask で管理し、新規導入・更新時の postinstall で Vrapper を導入します。
Vrapper は公式
[GitHub Release 0.74.0](https://github.com/vrapper/vrapper/releases/tag/0.74.0)
の `vrapper_0.74.0_20181124.zip` をバージョン・SHA-256 固定で取得し、
Nix store に展開したローカル p2 リポジトリを使います。
Vrapper の取得に SourceForge の更新サイトは使用しません。

DBeaver が起動中の場合は postinstall を中止するため、rebuild の前に終了してください。
Vrapper が導入済みならスキップし、DBeaver の更新で失われた場合は再導入します。
postinstall は cask の新規導入・更新時だけ実行されます。
cask がすでに最新の場合、rebuild だけでは失敗済みの postinstall は再実行されません。
その場合は DBeaver を終了し、生成 Brewfile の `dbeaver-community` にある `postinstall` コマンドを手動実行して再試行します（実機の変更を伴います）。
Vrapper の設定は Home Manager が管理する `.vrapperrc` に保持されます。
下流の flake では、この修正を含む上流リビジョンへ
`public-config` input の `flake.lock` を更新してから rebuild します。

実機への反映を伴わない自動検証:

```bash
nix build path:.#checks.aarch64-darwin.dbeaver-vrapper --no-link
nix flake check --no-build
```

自動検証は配布物・Brewfile・postinstall の分岐を確認します。
実アプリへの導入成功や SQL エディタでの Vim 操作は別の確認項目です。
実機反映後に DBeaver の Installation Details で Vrapper を確認し、SQL エディタで操作を確認してください。

## Troubleshooting

Determinate Nix 導入時に既存の `/etc/zshenv` や `/etc/zshrc` と競合することがあります。
エラーメッセージに従い、必要に応じて元のファイルをリネームまたは削除してください。

## Standalone Build

standalone build は `user-config` input を override して実行します。

```bash
darwin-rebuild build --impure \
  --flake path:.#${USER}-aarch64-darwin \
  --override-input user-config path:${HOME}/.config/nix
```

## Reusable Outputs

他の flake から使うために `lib.mkDarwinSystem`, `homeModules.default`,
`darwinModules.default` を公開しています。
これらは top-level で private な `user.toml` を読みません。

private 側では `public-config` を input にし、user / host 固有値と追加 module だけ渡します。

```nix
{
  inputs.public-config.url = "github:y-writings/dotfiles";

  outputs = { public-config, ... }: {
    darwinConfigurations.my-host = public-config.lib.mkDarwinSystem {
      system = "aarch64-darwin";
      username = "your-user";
      paths = {
        homeDir = "/Users/your-user";
        dotfilesRoot = "/Users/your-user/workspace/repos/github.com/y-writings/dotfiles-private";
        workspacePath = "/Users/your-user/workspace";
        ghqRootPath = "/Users/your-user/workspace/repos";
      };
      gitIdentity = {
        name = "Your Name";
        email = "you@example.com";
      };
      enabledInstallFeatures = [ ];
      secrets = { };
      extraDarwinModules = [ ./nix/darwin/private.nix ];
      extraHomeModules = [ ./nix/home/git-private.nix ];
    };
  };
}
```

追加 module は canonical base の後ろに merge されます。上書きが必要な場合は `lib.mkForce` などを使います。
Darwin 側には `username`, `enabledInstallFeatures`、
Home 側には `inputs`, `paths`, `secrets`, `gitIdentity` が渡ります。
