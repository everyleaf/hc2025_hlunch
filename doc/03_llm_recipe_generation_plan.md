# LLM経由レシピ生成機能実装計画

## 目的

プロンプトを選んで、LLM経由でレシピを生成して保存できるようにする

## 機能概要

- プロンプト詳細ページから「LLMでレシピ生成」ボタンを押す
- LM Studio経由でローカルLLMにプロンプトを送信
- 生成されたレシピ（タイトル、材料、作り方）をパース
- 新規レシピとしてデータベースに保存
- 生成されたレシピの詳細ページにリダイレクト

## 必要な準備

### LM Studio
- LM Studioでローカルサーバーを起動
- デフォルトエンドポイント: `http://localhost:1234/v1/chat/completions`

### 環境変数
- LM StudioのエンドポイントURL（カスタマイズする場合）
  - `.env`ファイルに `LLM_API_ENDPOINT` を設定（オプション）
  - gitignoreに`.env`を追加

### Gem追加
```ruby
gem 'dotenv-rails'
gem 'faraday'  # HTTP client
```

## 実装手順

### 1. 環境設定

#### 1.1 Gemfile更新
```ruby
gem 'dotenv-rails', groups: [:development, :test]
gem 'faraday'
```

#### 1.2 .envファイル作成（オプション）
```
LLM_API_ENDPOINT=http://localhost:1234/v1/chat/completions
```

#### 1.3 .gitignoreに追加
```
.env
```

#### 1.4 bundle install
```bash
bundle install
```

### 2. LLM API設定

#### 2.1 定数定義
- デフォルトエンドポイント: `http://localhost:1234/v1/chat/completions`
- 環境変数から上書き可能にする

### 3. レシピ生成サービスクラス作成

#### 3.1 RecipeGeneratorService
- `app/services/recipe_generator_service.rb`を作成
- LM Studio APIを呼び出してレシピを生成
- レスポンスをパースしてRecipeオブジェクトを作成
- エラーハンドリング（API呼び出し失敗、パース失敗など）

主なメソッド:
- `initialize(prompt)`: プロンプトを受け取る
- `generate`: レシピ生成を実行してRecipeオブジェクトを返す
- `call_llm_api`: LM Studio APIを呼び出す（Faraday使用）
- `parse_response(response)`: レスポンスをパースしてRecipeの属性に変換

APIリクエスト形式（OpenAI互換）:
```json
{
  "model": "local-model",
  "messages": [
    {"role": "system", "content": "システムプロンプト"},
    {"role": "user", "content": "ユーザーのプロンプト"}
  ],
  "temperature": 0.7
}
```

### 4. コントローラーの実装

#### 4.1 RecipesController に generate アクション追加
- `generate`: LLMでレシピ生成
  - プロンプトを取得
  - RecipeGeneratorServiceを呼び出し
  - 成功時: 生成されたレシピを保存してレシピ詳細にリダイレクト
  - 失敗時: エラーメッセージを表示してプロンプト詳細に戻る

### 5. ルーティング設定

#### 5.1 generateアクション追加
```ruby
resources :prompts do
  resources :recipes, shallow: true do
    post 'generate', on: :collection
  end
end
```

または

```ruby
resources :prompts do
  member do
    post 'generate_recipe'
  end
  resources :recipes, shallow: true
end
```

### 6. ビューの実装

#### 6.1 Prompts show view 更新
- 「LLMでレシピ生成」ボタンを追加
- 生成中の状態表示（ローディング）
- エラーメッセージ表示エリア

### 7. テスト実装

#### 7.1 RecipeGeneratorServiceのテスト
- `test/services/recipe_generator_service_test.rb`
  - 正常系: レシピが正しく生成される
  - 異常系: API呼び出し失敗時
  - 異常系: レスポンスパース失敗時

#### 7.2 Request spec追加
- `test/requests/recipes_test.rb`に追加
  - generate: レシピが生成されて保存される
  - generate: API失敗時にエラーメッセージが表示される

### 8. プロンプト設計

#### 8.1 システムプロンプト
LLMに渡すプロンプトの構造を設計:
- ユーザーのプロンプト本文を使用
- レシピのフォーマット指定（JSON形式など）
- 必須フィールド: title, ingredients, instructions

例:
```
以下のプロンプトに基づいてレシピを生成してください。
レスポンスは以下のJSON形式で返してください：

{
  "title": "レシピのタイトル",
  "ingredients": "材料のリスト（改行区切り）",
  "instructions": "作り方の手順（改行区切り）"
}

プロンプト:
{ユーザーのプロンプト本文}
```

## 実装の注意点

1. **LM Studio起動確認**: ローカルサーバーが起動しているか確認
2. **エラーハンドリング**: API呼び出し失敗、接続エラー、パース失敗などに対応
3. **タイムアウト**: API呼び出しにタイムアウトを設定（LLM生成は時間がかかる）
4. **レスポンスパース**: JSONパースが失敗した場合の処理
5. **ユーザーフィードバック**: 生成中の状態をユーザーに表示
6. **テスト**: 外部API呼び出しをモック化（WebMockなど）
7. **セキュリティ**: ユーザー入力のサニタイズ
8. **エンドポイント設定**: 環境変数で柔軟に変更可能にする

## 完了条件

- [ ] LM Studio起動確認
- [ ] 環境変数設定完了（オプション）
- [ ] Gem追加とインストール完了
- [ ] RecipeGeneratorService実装完了
- [ ] RecipesControllerのgenerateアクション実装完了
- [ ] ルーティング設定完了
- [ ] ビュー更新完了
- [ ] サービスのテスト完了
- [ ] Request specのテスト完了
- [ ] ブラウザで動作確認完了（LM Studioと連携）

## 今後の拡張案

- 生成オプションの追加（温度パラメータ、モデル選択など）
- 生成履歴の表示
- 生成されたレシピの評価機能
- 複数レシピの一括生成
