# OpenAI API切り替え実装計画

## 目的

ローカルLLM（LM Studio）からOpenAI公式APIに切り替える

## 背景

- ローカルLLMでは精度が不十分
- OpenAI APIを使用してより高品質なレシピ生成を実現

## 変更内容

### 1. 環境変数設定

#### 1.1 `.env`ファイル作成

`.env`ファイルを作成してAPIキーを設定（Gitには含めない）

```bash
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_API_BASE=https://api.openai.com/v1/
```

**注意**: `.env`ファイルは`.gitignore`に追加済みか確認

#### 1.2 dotenv-rails gem追加

環境変数を読み込むために`dotenv-rails` gemを追加（開発環境のみ）

```ruby
# Gemfile
group :development do
  gem 'dotenv-rails'
end
```

**注意**: テスト環境ではスタブを使用するため、dotenv-railsは不要

```bash
bundle install
```

### 2. OpenAI初期化設定変更

#### 2.1 `config/initializers/openai.rb`更新

現在の設定：
```ruby
OpenAI.configure do |config|
  config.uri_base = ENV.fetch("OPENAI_API_BASE", "http://localhost:1234/v1/")
  config.access_token = "dummy"
  config.request_timeout = 240
end
```

新しい設定：
```ruby
OpenAI.configure do |config|
  config.uri_base = ENV.fetch("OPENAI_API_BASE", "https://api.openai.com/v1/")
  config.access_token = ENV.fetch("OPENAI_API_KEY")
  config.request_timeout = 240
end
```

**変更点**:
- `uri_base`のデフォルト値をOpenAI公式エンドポイントに変更
- `access_token`を環境変数`OPENAI_API_KEY`から取得
- APIキーが設定されていない場合はエラーになる（`fetch`使用）

### 3. Promptモデルの変更

#### 3.1 モデル名変更

`app/models/prompt.rb`の`call_llm_api`メソッドでモデル名を変更

現在：
```ruby
parameters: {
  model: "local-model",
  ...
}
```

変更後：
```ruby
parameters: {
  model: "gpt-5-mini",
  ...
}
```

#### 3.2 システムプロンプトの調整（オプション）

OpenAI APIの方が指示に従いやすいため、システムプロンプトを簡潔にできる可能性がある

### 4. テスト

既存のテストは変更不要（モックを使用しているため）

### 5. 動作確認

#### 5.1 APIキー取得

1. OpenAIアカウント作成（https://platform.openai.com/）
2. API Keys ページでAPIキーを生成
3. `.env`ファイルに設定

#### 5.2 ブラウザでの動作確認

1. Railsサーバー起動
2. プロンプト詳細ページで「LLMでレシピ生成」ボタンをクリック
3. レシピが正しく生成されることを確認

## セキュリティ注意事項

1. **APIキーの管理**
   - `.env`ファイルをGitにコミットしない
   - `.gitignore`に`.env`が含まれていることを確認
   - 本番環境では環境変数を使用（Heroku、Render等）

2. **コスト管理**
   - OpenAI APIは従量課金
   - Usage limitsを設定することを推奨（https://platform.openai.com/usage）
   - 不要なAPI呼び出しを避ける

## 実装手順

### 手順1: dotenv-rails gem追加

```bash
# Gemfileに追加
bundle install
```

### 手順2: .envファイル作成

```bash
# .envファイルを作成してAPIキーを設定
echo "OPENAI_API_KEY=your_api_key_here" > .env
echo "OPENAI_API_BASE=https://api.openai.com/v1/" >> .env
```

### 手順3: .gitignoreに.envを追加（既にある場合はスキップ）

```bash
echo ".env" >> .gitignore
```

### 手順4: config/initializers/openai.rb更新

上記の新しい設定に更新

### 手順5: app/models/prompt.rbのモデル名変更

`model: "local-model"` → `model: "gpt-5-mini"`

### 手順6: テスト実行

```bash
rails test
```

### 手順7: 動作確認

Railsサーバーを起動して、ブラウザで動作確認

## 完了条件

- [x] dotenv-rails gem追加完了
- [x] .envファイル作成完了（APIキー設定済み）
- [x] .gitignoreに.env追加確認
- [x] OpenAI initializer更新完了
- [x] Promptモデルのモデル名変更完了
- [x] テストが全てパスすることを確認
- [ ] ブラウザで動作確認完了（OpenAI APIと連携）

## ロールバック手順

元のLM Studioに戻す場合：

1. `config/initializers/openai.rb`を元に戻す
2. `app/models/prompt.rb`のモデル名を`"local-model"`に戻す
3. LM Studioサーバーを起動

## 参考資料

- OpenAI API Documentation: https://platform.openai.com/docs/api-reference
- ruby-openai gem: https://github.com/alexrudall/ruby-openai
- OpenAI Pricing: https://openai.com/pricing
