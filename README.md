# y-writings' personal dotfiles

macOS (`aarch64-darwin`) を Nix + nix-darwin + Home Manager でセットアップするための dotfiles です。

## Initial Setup

`sudo` 実行権限と `git`, `curl` がある状態で以下を実行します。

```bash
curl -fsSL https://raw.githubusercontent.com/y-writings/dotfiles/main/script/bootstrap.sh -o bootstrap.sh
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

### DBeaver と Vrapper の更新

`mise run rebuild`（nix-darwin activation）で DBeaver Community Edition が新規インストールまたは更新されると、
Homebrew Cask の `postinstall` が Eclipse p2 Director を実行し、Vrapper を再導入します。
DBeaver が起動中の場合は安全のため強制終了せず、DBeaver を終了して rebuild を再実行するようエラーになります。
Vrapper の設定は Home Manager が `~/.vrapperrc` として管理するため、DBeaver の更新後も維持されます。

手動の `brew upgrade` では nix-darwin が生成する Brewfile の `postinstall` は実行されません。
DBeaver の更新には `mise run rebuild` を使用してください。手動で更新して Vrapper が失われた場合も、
次回の DBeaver の Cask 更新時に postinstall が実行されるよう、nix-darwin 経由で更新してください。
この構成では activation 時の Homebrew auto-update / upgrade が有効なため、rebuild は DBeaver 以外の
Homebrew 管理対象も更新します。

Vrapper は stable update site から導入され、その URL だけを p2 の trusted authority に指定しています。
配布物自体を Nix store に固定する構成ではないため、update site の時点の内容が導入されます。

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

他の flake から使うために `lib.mkDarwinSystem`, `homeModules.default`, `darwinModules.default` を公開しています。
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
Darwin 側には `username`, `enabledInstallFeatures`、Home 側には `inputs`, `paths`, `secrets`, `gitIdentity` が渡ります。
