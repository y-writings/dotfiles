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
1. `script/create-user-toml.sh` の対話実行（`$HOME/.config/nix/user.toml` 作成）
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
