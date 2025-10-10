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
- デフォルトエンドポイント: `http://localhost:1234/v1/`
- 任意のモデルを読み込んでサーバーを起動

### Gem追加
```ruby
gem 'ruby-openai'
```

Note: `ruby-openai` gemはカスタムエンドポイントをサポートしているため、LM Studioでも使用可能

## 実装手順

### 1. 環境設定

#### 1.1 Gemfile更新
```ruby
gem 'ruby-openai'
```

#### 1.2 bundle install
```bash
bundle install
```

### 2. OpenAI gem設定

#### 2.1 initializer作成
`config/initializers/openai.rb`を作成

```ruby
OpenAI.configure do |config|
  config.uri_base = ENV.fetch("OPENAI_API_BASE", "http://localhost:1234/v1/")
  config.access_token = "dummy" # LM Studioはトークン不要だが設定は必須
  config.request_timeout = 240 # LLM生成は時間がかかるためタイムアウトを長めに
end
```

### 3. Promptモデルにレシピ生成メソッド追加

#### 3.1 Promptモデルに `generate_recipe` メソッド追加
- `app/models/prompt.rb`に直接実装
- `ruby-openai` gemを使ってLM Studio APIを呼び出してレシピを生成
- レスポンスをパースしてRecipeオブジェクトを返す
- エラーハンドリング（API呼び出し失敗、パース失敗など）

主なメソッド:
- `generate_recipe`: レシピ生成を実行してRecipeオブジェクトを返す
- `call_llm_api` (private): OpenAI gem（LM Studio接続）を使ってAPI呼び出し
- `parse_llm_response(response)` (private): レスポンスをパースしてRecipeの属性ハッシュに変換

使用例:
```ruby
prompt = Prompt.find(1)
recipe = prompt.generate_recipe
# => #<Recipe title: "...", ingredients: "...", instructions: "...">
```

実装イメージ:
```ruby
class Prompt < ApplicationRecord
  def generate_recipe
    response = call_llm_api
    recipe_attrs = parse_llm_response(response)
    recipes.build(recipe_attrs)
  end

  private

  def call_llm_api
    client = OpenAI::Client.new
    client.chat(
      parameters: {
        model: "local-model",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      }
    )
  end

  def parse_llm_response(response)
    # JSONパース処理
  end
end
```

### 4. コントローラーの実装

#### 4.1 RecipesController に generate アクション追加
- `generate`: LLMでレシピ生成
  - プロンプトを取得
  - `prompt.generate_recipe` を呼び出し
  - 成功時: 生成されたレシピを保存してレシピ詳細にリダイレクト
  - 失敗時: エラーメッセージを表示してプロンプト詳細に戻る

実装イメージ:
```ruby
def generate
  @prompt = Prompt.find(params[:prompt_id])
  @recipe = @prompt.generate_recipe

  if @recipe.save
    redirect_to @recipe, notice: "レシピを生成しました。"
  else
    redirect_to @prompt, alert: "レシピの生成に失敗しました。"
  end
rescue => e
  redirect_to @prompt, alert: "エラーが発生しました: #{e.message}"
end
```

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

### 7. プロンプト設計

#### 7.1 システムプロンプト
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

### 8. テスト実装

#### 8.1 Promptモデルテストに追加
- `test/models/prompt_test.rb`に追加
  - `generate_recipe`メソッドのテスト
  - 正常系: レシピが正しく生成される
  - 異常系: API呼び出し失敗時
  - 異常系: レスポンスパース失敗時
  - WebMockでAPI呼び出しをモック化

#### 8.2 Request spec追加
- `test/requests/recipes_test.rb`に追加
  - generate: レシピが生成されて保存される
  - generate: API失敗時にエラーメッセージが表示される

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
- [ ] ruby-openai gem追加とインストール完了
- [ ] OpenAI initializer設定完了
- [ ] Promptモデルに`generate_recipe`メソッド実装完了
- [ ] RecipesControllerのgenerateアクション実装完了
- [ ] ルーティング設定完了
- [ ] ビュー更新完了
- [ ] Promptモデルテスト完了
- [ ] Request specのテスト完了
- [ ] ブラウザで動作確認完了（LM Studioと連携）

## 今後の拡張案

- 生成オプションの追加（温度パラメータ、モデル選択など）
- 生成履歴の表示
- 生成されたレシピの評価機能
- 複数レシピの一括生成
