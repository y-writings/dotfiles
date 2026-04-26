# macOS 向け個人用 dotfiles

## 前提条件

- macOS (`aarch64-darwin`)
- `sudo` 実行権限、および、`git` , `curl` が必要です。

## 実行後のディレクトリ構成概要

```
.
└── $HOME
    ├── some application default private dotfiles # e.g. .config, .zshrc
    └── workspace/
        ├── assets/
        ├── bin/
        └── repos/
```

## 実行方法

### 条件

- システム構成: Nix + nix-darwin + Home Manager
- 個人設定ファイル: 初回実行時に `$HOME/.config/nix/user.toml` を対話形式で作成

## 実行手順

### 初回

クリーンな macOS 環境で `bootstrap.sh` を実行します。

```bash
curl -fsSL https://raw.githubusercontent.com/y-writings/dotfiles/main/script/bootstrap.sh -o bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh
```

下記が実行されます。

1. Xcode Command Line Tools の導入
1. Determinate Nix の導入
1. `https://www.github.com/y-writings/dotfiles.git` の clone
1. `script/create-user-toml.sh` の対話実行（`$HOME/.config/nix/user.toml` を作成）
1. 初回 `nix-darwin switch`

#### エラー発生時

多くの場合、Determinate Nix 導入時の初期ファイルと、既存の macOS 上のファイルが競合しています。
エラーメッセージに従い、必要に応じて元のファイルをリネームまたは削除します。
以下のファイルでエラーが出やすいです。

- /etc/zshenv
- /etc/zshrc

### 2回目以降

初回実行で `mise` の導入が完了しています。
初回実行以降はタスクランナーで実行します。

```bash
mise run rebuild
```

## その他

flake.lockの更新など、必要なコマンドは `mise` のタスクランナーに用意しています。
また、rebuild後、一部のパッケージで初期化コマンドが必要となります。
ただし、post用のコマンドも用意しており、rebuildコマンド後に自動実行されるため、通常意識することはありません。

## reusable module outputs

この repository は standalone 実行に加えて、他の flake から再利用できる public output も提供します。

- `lib.mkDarwinSystem`: public な canonical nix-darwin builder
- `homeModules.default`: public な Home Manager base module
- `darwinModules.default`: public な nix-darwin base module

これらの reusable output は top-level で private な `user.toml` を読みません。
特に `lib.mkDarwinSystem` は、この repository が使う shared flake stack と canonical な module order を public 側の責務として閉じ込めた builder です。
private 側では `nixpkgs`, `home-manager`, `nix-darwin`, `determinate`, `nix-homebrew`, `vscode-extensions`, `ni-zsh` などを再宣言せず、`public-config` だけを input にして last-mile overlay を足す想定です。

builder の public interface は次のとおりです。

```nix
public-config.lib.mkDarwinSystem {
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
  extraDarwinModules = [ ];
  extraHomeModules = [ ];
}
```

private 側が注入する責務は user / host 固有の data と overlay module だけです。

- `username`
- `paths = { homeDir; dotfilesRoot; workspacePath; ghqRootPath; }`
- `gitIdentity`
- `enabledInstallFeatures`
- `secrets`
- `extraDarwinModules`
- `extraHomeModules`

`extraDarwinModules` と `extraHomeModules` は canonical base の後ろに追加されます。
ただし override の最終結果は Nix module merge semantics (`mkDefault`, `mkForce`, list merge など) に従います。
そのため private 側では additive な設定はそのまま足し、base の値を明示的に上書きしたい場合は必要に応じて `lib.mkForce` などを使ってください。

現在の引数の見え方は layer ごとに少し異なります。

- `extraDarwinModules` では `username` と `enabledInstallFeatures` が `specialArgs` 経由で見えます。
- `extraHomeModules` では `inputs`, `paths`, `secrets`, `gitIdentity` が `home-manager.extraSpecialArgs` 経由で見えます。

たとえば private 側では次のように利用できます。

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
      extraDarwinModules = [
        ./nix/darwin/private.nix
      ];
      extraHomeModules = [
        ./nix/home/git-private.nix
      ];
    };
  };
}
```

standalone build は従来どおり `user-config` input を override して実行します。

```bash
nix flake show .
nix eval .#lib.mkDarwinSystem
nix eval .#homeModules.default
nix eval .#darwinModules.default
darwin-rebuild build --impure --flake path:.#${USER}-aarch64-darwin --override-input user-config path:${HOME}/.config/nix
```
