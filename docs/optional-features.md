# Optional Features

一部のアプリは既定で無効化されており、`~/.config/nix/user.toml`（または `lib.mkDarwinSystem`）の `enabledInstallFeatures` に追加して次回の rebuild で導入します。

| Feature | 内容 | 補足 |
| :--- | :--- | :--- |
| `tailscale` | Tailscale Standalone (`tailscale-app`) | VPN 設定・認証は導入後にアプリから実施 |
| `lm-studio` | LM Studio (`lm-studio`) | - |

既存の feature を残したまま追記してください。無効化して rebuild すると、`cleanup = "zap"` に従いアプリと関連設定が削除対象になります。

```toml
enabledInstallFeatures = ["productivity", "tailscale", "lm-studio"]
```
