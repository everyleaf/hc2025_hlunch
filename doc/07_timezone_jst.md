# タイムゾーン表示をJSTに変更

## Context
Issue #11: 日時がUTCのまま表示されている。DBへの保存はUTCのまま、表示時のみJSTに変換する。

## 方針
`config/application.rb` に `config.time_zone = "Tokyo"` を設定する。

Railsの標準的な動作として:
- DBへの保存は引き続きUTC（`config.active_record.default_timezone` のデフォルトが `:utc`）
- アプリケーション層（ビューでの `.strftime()` 等）では `config.time_zone` で指定したタイムゾーンに自動変換される

これにより、ビュー側の変更は不要。

## 修正ファイル

- `config/application.rb`: `config.time_zone = "Tokyo"` を設定
- `spec/models/timezone_spec.rb`: タイムゾーンのテストを追加
