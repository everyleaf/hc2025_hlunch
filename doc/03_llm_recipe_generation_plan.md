# LLM経由レシピ生成機能実装計画

## 目的

プロンプトを選んで、LLM経由でレシピを生成して保存できるようにする

## 機能概要

- プロンプト詳細ページから「LLMでレシピ生成」ボタンを押す
- LLM（OpenAI API）にプロンプトを送信
- 生成されたレシピ（タイトル、材料、作り方）をパース
- 新規レシピとしてデータベースに保存
- 生成されたレシピの詳細ページにリダイレクト

## 必要な準備

### 環境変数
- OpenAI APIキーの設定
  - `.env`ファイルに `OPENAI_API_KEY` を設定
  - gitignoreに`.env`を追加

### Gem追加
```ruby
gem 'dotenv-rails'
gem 'ruby-openai'
```

## 実装手順

### 1. 環境設定

#### 1.1 Gemfile更新
```ruby
gem 'dotenv-rails', groups: [:development, :test]
gem 'ruby-openai'
```

#### 1.2 .envファイル作成
```
OPENAI_API_KEY=your_api_key_here
```

#### 1.3 .gitignoreに追加
```
.env
```

#### 1.4 bundle install
```bash
bundle install
```

### 2. OpenAI設定

#### 2.1 initializer作成
`config/initializers/openai.rb`を作成し、OpenAIクライアントを設定

### 3. レシピ生成サービスクラス作成

#### 3.1 RecipeGeneratorService
- `app/services/recipe_generator_service.rb`を作成
- OpenAI APIを呼び出してレシピを生成
- レスポンスをパースしてRecipeオブジェクトを作成
- エラーハンドリング（API呼び出し失敗、パース失敗など）

主なメソッド:
- `initialize(prompt)`: プロンプトを受け取る
- `generate`: レシピ生成を実行してRecipeオブジェクトを返す
- `call_openai_api`: OpenAI APIを呼び出す
- `parse_response(response)`: レスポンスをパースしてRecipeの属性に変換

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

1. **APIキー管理**: APIキーは環境変数で管理し、gitにコミットしない
2. **エラーハンドリング**: API呼び出し失敗、レート制限、パース失敗などに対応
3. **タイムアウト**: API呼び出しにタイムアウトを設定
4. **レスポンスパース**: JSONパースが失敗した場合の処理
5. **ユーザーフィードバック**: 生成中の状態をユーザーに表示
6. **コスト管理**: API使用量の監視
7. **テスト**: 外部API呼び出しをモック化
8. **セキュリティ**: ユーザー入力のサニタイズ

## 完了条件

- [ ] 環境変数設定完了
- [ ] Gem追加とインストール完了
- [ ] OpenAI設定完了
- [ ] RecipeGeneratorService実装完了
- [ ] RecipesControllerのgenerateアクション実装完了
- [ ] ルーティング設定完了
- [ ] ビュー更新完了
- [ ] サービスのテスト完了
- [ ] Request specのテスト完了
- [ ] ブラウザで動作確認完了

## 今後の拡張案

- 生成オプションの追加（温度パラメータ、モデル選択など）
- 生成履歴の表示
- 生成されたレシピの評価機能
- 複数レシピの一括生成
