# 08: BASIC認証の追加

## 背景

アプリケーションに認証がないため、環境変数`BASIC_AUTH_USERNAME`/`BASIC_AUTH_PASSWORD`が設定されている場合のみBASIC認証をかける。未設定時はスキップ。

## 変更ファイル

1. **`app/controllers/application_controller.rb`** — `before_action`でBASIC認証を追加
   - `ENV["BASIC_AUTH_USERNAME"]`と`ENV["BASIC_AUTH_PASSWORD"]`が両方presentな場合のみ認証
   - `ActiveSupport::SecurityUtils.secure_compare`でタイミング攻撃防止

2. **`.env.sample`** — `BASIC_AUTH_USERNAME`/`BASIC_AUTH_PASSWORD`のサンプル値を追加

3. **`spec/requests/basic_auth_spec.rb`**（新規） — BASIC認証の動作テスト
   - 環境変数設定時: 認証なし→401、正しい認証→200、誤った認証→401
   - 既存テストは環境変数未設定のため影響なし

## 検証

- `bundle exec rspec` で既存テスト＋新規テストが全てパスすること
- `bundle exec rubocop` で編集ファイルのLintパス確認
