# Vrapper GitHub Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** DBeaver の postinstall が SourceForge の障害に影響されず、固定した Vrapper 0.74.0 を導入できるようにする。

**Architecture:** 公式 GitHub Release の ZIP を `pkgs.fetchurl` でハッシュ固定して取得し、
`pkgs.runCommand` と `unzip` で Nix store に展開する。
`homebrew.nix` 内のローカル derivation として管理し、postinstall の第1引数で渡す。
スクリプトは `file://` URI を p2 Director に渡す。

**Tech Stack:** Nix / nix-darwin / Homebrew Bundle / POSIX sh / Eclipse p2

**Spec:** [VIS-467](https://linear.app/visros/issue/VIS-467)

## Global Constraints

- 配布バージョンは `0.74.0`、ファイルは `vrapper_0.74.0_20181124.zip`。
- ZIP の SHA-256 は `sha256-q4IZhikiVaIStrUAlxd3dCPkpDFNrCdoyQ5MFLTvmaY=`。
- DBeaver 起動中は中止し、導入済みはスキップ、本体更新で feature がなくなった場合は再導入する。
- p2 の IU は `net.sourceforge.vrapper.feature.group`。
  展開先の feature 名は `net.sourceforge.vrapper_0.74.0`
  （ZIP の feature.xml / content.xml で確認済み）。
- Home Manager の Vrapper 設定と DBeaver 設定は維持する。
- activation、実アプリへのインストール、sudo は実行しない。
- GitHub パッケージ registry には登録しない。これは Home Manager にインストールするアプリではなく、postinstall 専用の固定リポジトリである。

## Review Focus

- 実配布 ZIP と p2 メタデータの配置、feature / plugin の整合性。
- Nix → Brewfile → shell → p2 の引数と store 参照の保持。
- 新規導入・本体更新後と、導入済み再実行の区別。
- DBeaver 起動中・ランチャー不在・p2 失敗の終了状態。
- SourceForge に戻る参照先や外部ミラーを追加しない。

## Contract Map

テスト設計は Tier 2。外部 p2 形式とアプリへの postinstall 境界を扱うため、
独立レビューと実 ZIP の検査を併用する。実機導入の成功は自動検証から推定しない。
現時点で Tier 3 を要する仕様上の争点はない。

- Nix derivation: 固定ハッシュの実 ZIP を展開し、content.jar / artifacts.jar と
  core feature / plugins を保持するビルドチェック。
- nix-darwin module: 生成された Brewfile の postinstall が
  展開済み store パスを引数として保持する。
- postinstall shell: 一時 fixture の新規導入・導入済み・更新後・起動中・
  ランチャー不在・p2 失敗を、実アプリを呼ばず検証する。
- Home Manager: 既存の `.vrapperrc` と
  `home.activation.disableDbeaverAutoUpdateCheck` の宣言は変更しない。

## Task 1: Local p2 repository and postinstall integration

**Files:**

- Modify: `nix/darwin/homebrew.nix`
- Modify: `nix/darwin/homebrew-postinstall/dbeaver-vrapper.sh`
- Modify: `nix/checks/default.nix`
- Create: `nix/checks/dbeaver-vrapper.nix`
- Create: `nix/checks/dbeaver-vrapper.py`
- Modify: `README.md`

**Interfaces:** `dbeaver-vrapper.sh <absolute-store-repository-path>`;
existing cask token and IU remain unchanged.

- [x] Confirm SourceForge HTTP 404, prefetch the official ZIP, inspect its
      metadata, and run the baseline
      `nix flake check --no-build --no-write-lock-file`.
- [x] Independently review contract ownership and the minimal verification
      cases before finalizing tests.
- [x] Add a focused flake check and observe it fail because postinstall does
      not accept a local repository / recognize the real installed feature name.
- [x] Add the fixed ZIP derivation, pass its path through postinstall,
      switch p2 to `file://`, and correct the feature-name match.
- [x] Build the focused check:

  ```bash
  nix build path:.#checks.aarch64-darwin.dbeaver-vrapper \
    --no-link --no-write-lock-file
  ```

- [x] Document distribution source, downstream flake update, verification,
      and pending real-app confirmation in README.
- [x] Run Nix formatting, shell syntax / ShellCheck, generated Brewfile
      validation, and `nix flake check --no-build --no-write-lock-file`.
- [x] Review the final diff and report automated verification separately
      from real-app installation / GUI checks.

## Verification Results

- 固定 ZIP の取得・展開、p2 メタデータと core feature / plugins の整合性確認に成功。
- 生成 Brewfile の Ruby 構文と postinstall 引数、store 参照の保持を確認。
- 6 件の自動検証に成功（配布物 1 件、postinstall の分岐 5 件）。修正前はローカルパスの未伝達、SourceForge 参照、導入済み判定で失敗することを確認済み。
- `nixfmt --check`、shell 構文 / ShellCheck、
  `nix eval .#darwinModules.default`、
  `nix flake check --no-build --no-write-lock-file` に成功。
- 既存警告は `system` の廃止予定名、Home Manager の context を持たない store 参照、未検査の `lib` output。修正前にも発生していた。
- 実機への activation と DBeaver への実導入・GUI 操作確認は未実施。自動検証は実アプリでの互換性を保証するものではない。
- 独立レビューは Approve。Critical / Important / Minor の指摘なし。Tier 2 で十分と判断。
