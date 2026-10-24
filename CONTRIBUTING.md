# コントリビューション

## プルリクエストタイトル

プルリクエストのタイトルは、次の Conventional Commits 形式にする。

```text
<type>[optional scope]: <description>
```

例: `fix:`、`feat:`、`docs:`。スコープは任意で、`feat(scope):` のように付ける。

`type` は Semantic PR check
（`.github/workflows/00-semantic-pr-check.yaml`）が受け付ける次のいずれかだけを使う。

- `build`
- `chore`
- `ci`
- `docs`
- `feat`
- `fix`
- `perf`
- `refactor`
- `revert`
- `style`
- `test`

説明（`<description>`）の末尾にピリオド（`.`）を付けない。

### 良い例

```text
docs: プルリクエストの手順を追加
fix(actions): プルリクエストタイトルを検証
feat(scope): 対象を明示して機能を追加
```

### 悪い例

```text
プルリクエストの手順を追加
docs: プルリクエストの手順を追加.
feature: 新機能を追加
```

次は Semantic PR check で失敗する。

- 型プレフィックスがない
- 説明の末尾が `.`
- 許可されていない型（例: `feature`）
