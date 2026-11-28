# y-writings' personal dotfiles

macOS (`aarch64-darwin`) 環境を Nix + nix-darwin + Home Manager で宣言的に構築・管理するための dotfiles です。

## Initial Setup

`sudo` 権限と `git`, `curl` が利用できる状態で、以下を実行します。

```bash
curl -fsSL -o bootstrap.sh \
  https://raw.githubusercontent.com/y-writings/dotfiles/main/script/bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh
```

Xcode Command Line Tools、Determinate Nix、`~/.config/nix/user.toml`、nix-darwin 環境まで一括でセットアップされます。

## Maintenance

初期セットアップ後の構成反映は `mise` で実行します。

```bash
mise run rebuild
```

その他のタスク一覧は `mise tasks` で確認できます。

### Build Check (反映なし)

実機へ反映せずにビルドのみ検証する場合は、`user-config` を指定して実行します。

```bash
darwin-rebuild build --impure \
  --flake path:.#${USER}-aarch64-darwin \
  --override-input user-config path:${HOME}/.config/nix
```

## Optional Features

`enabledInstallFeatures` で追加できるオプション機能（Tailscale、LM Studio 等）の詳細は [docs/optional-features.md](docs/optional-features.md) を参照してください。

## Reusable Outputs

外部 flake（private 設定など）から利用できるよう、`lib.mkDarwinSystem`, `homeModules.default`, `darwinModules.default` を公開しています。

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

- `extraDarwinModules` / `extraHomeModules` はベース設定の後ろにマージされます（上書きする場合は `lib.mkForce` 等を使用）。
- Darwin 側には `username`, `enabledInstallFeatures`、Home 側には `inputs`, `paths`, `secrets`, `gitIdentity` が渡されます。
