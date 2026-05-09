# nix/home/files

このディレクトリ配下の一部設定ファイルは、Home Manager の
`mkOutOfStoreSymlink` を使って参照しています。

## なぜ out-of-store symlink を使うのか

対象ツール（例: エディタやキーバインド管理ツール）は、実行中に設定ファイルを書き換えることがあります。
`source = ./...`（in-store）で管理すると、Nix store 上の読み取り専用ファイルになるため、
ツール側での更新が失敗します。

そのため、このリポジトリでは「ツール側更新を許容する」ことを優先し、
out-of-store symlink を採用しています。

## トレードオフ

- メリット: ツール側の設定変更（GUI操作や自動更新）がそのまま反映される
- デメリット: ローカル checkout パス（`paths.dotfilesRoot`）への依存が発生する

これは意図的な設計上のトレードオフです。

## 運用方針

- 再現性は `paths.dotfilesRoot` を含む `paths` を明示設定することで担保する
- 「ツール側で更新される可能性があるファイル」は out-of-store を維持する
- 完全な読み取り専用で問題ないファイルのみ in-store 管理を検討する
