# プロンプト合成機能実装計画

## 目的

複数のプロンプトをLLMに合成させて、新たなプロンプトを生成できるようにする

## 機能概要

- プロンプト一覧画面で複数のプロンプトを選択
- 「選択したプロンプトを合成」ボタンをクリック
- LLMが選択されたプロンプトを分析・合成して新しいプロンプトを生成
- 合成結果（タイトルとプロンプト本文）を確認・編集できる画面を表示
- 保存すると新しいプロンプトとしてデータベースに保存

## ユースケース例

**例1: シンプルな合成**
- プロンプト1: "カレーのレシピを教えてください"
- プロンプト2: "辛い料理のレシピを教えてください"
- 合成結果: "辛いカレーのレシピを教えてください"

**例2: 複雑な合成**
- プロンプト1: "和食のレシピ"
- プロンプト2: "ヘルシーな料理"
- プロンプト3: "30分以内で作れる料理"
- 合成結果: "30分以内で作れるヘルシーな和食のレシピ"

## データフロー

1. ユーザーが一覧画面で2つ以上のプロンプトを選択
2. 「合成」ボタンをクリック
3. サーバーに選択されたプロンプトのIDを送信
4. Promptモデルの`compose_prompts`メソッドが呼ばれる
5. LLM APIに合成リクエストを送信
6. LLMが合成されたプロンプト（タイトル + 本文）をJSON形式で返す
7. 合成結果を表示する画面にリダイレクト
8. ユーザーが内容を確認・編集
9. 保存ボタンで新しいプロンプトとして保存

## 実装手順

### 1. データモデル

変更不要（既存のPromptモデルを使用）

### 2. ルーティング

#### 2.1 `config/routes.rb`にcomposeアクション追加

```ruby
resources :prompts do
  collection do
    get 'compose_form'  # 合成結果の確認・編集フォーム表示
    post 'compose'      # 合成実行
  end
  member do
    post 'generate_recipe', to: 'recipes#generate'
  end
  resources :recipes, shallow: true
end
```

- `GET /prompts/compose_form?ids[]=1&ids[]=2`: 合成結果表示フォーム
- `POST /prompts/compose`: 合成実行

### 3. Promptモデル

#### 3.1 `compose_prompts`クラスメソッド追加

`app/models/prompt.rb`に以下を追加：

```ruby
# 複数のプロンプトをLLMで合成
# @param prompt_ids [Array<Integer>] 合成するプロンプトのIDの配列
# @return [Hash] { title: String, prompt: String }
def self.compose_prompts(prompt_ids)
  prompts = where(id: prompt_ids).order(:id)
  raise ArgumentError, "少なくとも2つのプロンプトを選択してください" if prompts.count < 2

  response = call_compose_llm_api(prompts)
  parse_compose_response(response)
end

private

def self.call_compose_llm_api(prompts)
  client = OpenAI::Client.new
  client.chat(
    parameters: {
      model: "gpt-5-mini",
      messages: [
        { role: "system", content: compose_system_prompt },
        { role: "user", content: build_compose_user_prompt(prompts) }
      ],
      temperature: 0.7
    }
  )
end

def self.compose_system_prompt
  <<~PROMPT
    あなたは複数のレシピ生成用プロンプトを分析して、それらを統合した新しいプロンプトを生成するアシスタントです。

    入力された複数のプロンプトはすべてレシピ生成のためのものです。
    それぞれのプロンプトの意図（料理の種類、調理法、特徴など）を理解し、それらの要素を自然に組み合わせた新しいレシピ生成用プロンプトを作成してください。

    レスポンスは以下のJSON形式で返してください：

    {
      "title": "合成されたプロンプトのタイトル",
      "prompt": "合成されたプロンプト本文"
    }

    重要：
    - 各プロンプトの核心的な要素（料理のジャンル、調理法、特徴、制約など）を抽出して組み合わせること
    - 矛盾する要素がある場合は自然に調和させること
    - レシピ生成の文脈を保つこと
    - 自然で分かりやすい日本語にすること
    - 冗長にならないよう簡潔にまとめること
  PROMPT
end

def self.build_compose_user_prompt(prompts)
  prompt_list = prompts.map.with_index(1) do |p, i|
    "プロンプト#{i}:\nタイトル: #{p.title}\n内容: #{p.prompt}"
  end.join("\n\n")

  <<~PROMPT
    以下のプロンプトを合成してください：

    #{prompt_list}
  PROMPT
end

def self.parse_compose_response(response)
  content = response.dig("choices", 0, "message", "content")
  Rails.logger.info("LLM Compose Response Content: #{content}")

  # JSONブロックを抽出
  json_str = if content =~ /```json\s*(\{.*?\})\s*```/m
    $1
  elsif content =~ /(\{.*\})/m
    $1
  else
    content
  end

  Rails.logger.info("Extracted Compose JSON String: #{json_str}")

  json_data = JSON.parse(json_str)

  {
    title: json_data["title"],
    prompt: json_data["prompt"]
  }
end
```

### 4. PromptsController

#### 4.1 `compose`と`compose_form`アクション追加

```ruby
# POST /prompts/compose
def compose
  prompt_ids = params[:prompt_ids] || []

  if prompt_ids.size < 2
    redirect_to prompts_path, alert: "少なくとも2つのプロンプトを選択してください。"
    return
  end

  begin
    @composed = Prompt.compose_prompts(prompt_ids)
    @selected_prompts = Prompt.where(id: prompt_ids).order(:id)
    render :compose_form
  rescue => e
    redirect_to prompts_path, alert: "プロンプトの合成に失敗しました: #{e.message}"
  end
end

# GET /prompts/compose_form (合成結果の表示・編集用)
def compose_form
  # composeアクションから呼ばれるため、直接のアクセスは不要
  redirect_to prompts_path
end
```

#### 4.2 Strong Parameters更新

既存の`prompt_params`メソッドはそのまま使用

### 5. ビュー実装

#### 5.1 プロンプト一覧画面更新 (`app/views/prompts/index.html.erb`)

チェックボックスと合成ボタンを追加：

```erb
<div class="container mt-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>プロンプト一覧</h1>
    <%= link_to "新規作成", new_prompt_path, class: "btn btn-primary" %>
  </div>

  <%= form_with url: compose_prompts_path, method: :post, local: true do |f| %>
    <div class="mb-3">
      <%= button_tag type: "submit", class: "btn btn-success",
          onclick: "return validateSelection()" do %>
        <i class="bi bi-magic"></i> 選択したプロンプトを合成
      <% end %>
      <small class="text-muted ms-2">（2つ以上選択してください）</small>
    </div>

    <% if @prompts.any? %>
      <div class="list-group">
        <% @prompts.each do |prompt| %>
          <div class="list-group-item">
            <div class="d-flex align-items-start">
              <div class="form-check me-3">
                <%= check_box_tag 'prompt_ids[]', prompt.id, false,
                    class: 'form-check-input prompt-checkbox' %>
              </div>
              <div class="flex-grow-1">
                <h5 class="mb-1">
                  <%= link_to prompt.title, prompt_path(prompt), class: "text-decoration-none" %>
                </h5>
                <p class="mb-1 text-muted"><%= truncate(prompt.prompt, length: 100) %></p>
                <small class="text-muted">
                  レシピ数: <%= prompt.recipes.count %> |
                  作成日: <%= prompt.created_at.strftime("%Y年%m月%d日") %>
                </small>
              </div>
              <div class="btn-group ms-3">
                <%= link_to "詳細", prompt_path(prompt), class: "btn btn-sm btn-outline-secondary" %>
                <%= link_to "編集", edit_prompt_path(prompt), class: "btn btn-sm btn-outline-primary" %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    <% else %>
      <div class="alert alert-info">
        プロンプトがまだ登録されていません。
      </div>
    <% end %>
  <% end %>
</div>

<script>
  function validateSelection() {
    const checked = document.querySelectorAll('.prompt-checkbox:checked');
    if (checked.length < 2) {
      alert('少なくとも2つのプロンプトを選択してください。');
      return false;
    }
    return true;
  }
</script>
```

#### 5.2 合成結果表示・編集フォーム作成 (`app/views/prompts/compose_form.html.erb`)

```erb
<div class="container mt-4">
  <h1>プロンプト合成結果</h1>

  <div class="card mb-4">
    <div class="card-header">
      <h5 class="mb-0">合成元のプロンプト</h5>
    </div>
    <div class="card-body">
      <% @selected_prompts.each_with_index do |prompt, index| %>
        <div class="mb-3">
          <strong>プロンプト<%= index + 1 %>:</strong> <%= prompt.title %>
          <p class="text-muted mb-0"><%= prompt.prompt %></p>
        </div>
      <% end %>
    </div>
  </div>

  <div class="card mb-4">
    <div class="card-header">
      <h5 class="mb-0">合成結果（編集可能）</h5>
    </div>
    <div class="card-body">
      <%= form_with model: Prompt.new, url: prompts_path, local: true do |f| %>
        <div class="mb-3">
          <%= f.label :title, "タイトル", class: "form-label" %>
          <%= f.text_field :title, value: @composed[:title], class: "form-control", required: true %>
        </div>

        <div class="mb-3">
          <%= f.label :prompt, "プロンプト本文", class: "form-label" %>
          <%= f.text_area :prompt, value: @composed[:prompt], rows: 6, class: "form-control", required: true %>
        </div>

        <div class="d-flex gap-2">
          <%= f.submit "保存", class: "btn btn-primary" %>
          <%= link_to "キャンセル", prompts_path, class: "btn btn-secondary" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

### 6. テスト実装

#### 6.1 Promptモデルテスト (`test/models/prompt_test.rb`)

```ruby
test "compose_prompts: 2つのプロンプトを合成できる" do
  prompt1 = Prompt.create!(title: "カレー", prompt: "カレーのレシピを教えてください")
  prompt2 = Prompt.create!(title: "辛い料理", prompt: "辛い料理のレシピを教えてください")

  mock_response = {
    "choices" => [{
      "message" => {
        "content" => '{"title":"辛いカレー","prompt":"辛いカレーのレシピを教えてください"}'
      }
    }]
  }

  OpenAI::Client.stub(:new, -> {
    mock_client = Minitest::Mock.new
    mock_client.expect(:chat, mock_response)
    mock_client
  }.call) do
    result = Prompt.compose_prompts([prompt1.id, prompt2.id])
    assert_equal "辛いカレー", result[:title]
    assert_equal "辛いカレーのレシピを教えてください", result[:prompt]
  end
end

test "compose_prompts: 1つのプロンプトしか選択されていない場合はエラー" do
  prompt1 = Prompt.create!(title: "カレー", prompt: "カレーのレシピ")

  assert_raises(ArgumentError) do
    Prompt.compose_prompts([prompt1.id])
  end
end

test "compose_prompts: プロンプトが選択されていない場合はエラー" do
  assert_raises(ArgumentError) do
    Prompt.compose_prompts([])
  end
end

test "compose_prompts: API呼び出し失敗時に例外が発生する" do
  prompt1 = Prompt.create!(title: "テスト1", prompt: "内容1")
  prompt2 = Prompt.create!(title: "テスト2", prompt: "内容2")

  OpenAI::Client.stub(:new, -> {
    mock_client = Minitest::Mock.new
    mock_client.expect(:chat, nil) do
      raise Faraday::Error.new("接続エラー")
    end
    mock_client
  }.call) do
    assert_raises(Faraday::Error) do
      Prompt.compose_prompts([prompt1.id, prompt2.id])
    end
  end
end
```

#### 6.2 Request spec (`test/requests/prompts_test.rb`)

```ruby
test "compose: 複数プロンプトが選択された場合に合成フォームが表示される" do
  prompt1 = Prompt.create!(title: "テスト1", prompt: "内容1")
  prompt2 = Prompt.create!(title: "テスト2", prompt: "内容2")

  mock_response = {
    "choices" => [{
      "message" => {
        "content" => '{"title":"合成タイトル","prompt":"合成内容"}'
      }
    }]
  }

  OpenAI::Client.stub(:new, -> {
    mock_client = Minitest::Mock.new
    mock_client.expect(:chat, mock_response)
    mock_client
  }.call) do
    post compose_prompts_path, params: { prompt_ids: [prompt1.id, prompt2.id] }
    assert_response :success
    assert_includes response.body, "合成タイトル"
    assert_includes response.body, "合成内容"
  end
end

test "compose: 1つのプロンプトのみ選択された場合はエラーメッセージ" do
  prompt1 = Prompt.create!(title: "テスト1", prompt: "内容1")

  post compose_prompts_path, params: { prompt_ids: [prompt1.id] }
  assert_redirected_to prompts_path
  assert_match(/少なくとも2つ/, flash[:alert])
end

test "compose: プロンプトが選択されていない場合はエラーメッセージ" do
  post compose_prompts_path, params: { prompt_ids: [] }
  assert_redirected_to prompts_path
  assert_match(/少なくとも2つ/, flash[:alert])
end
```

### 7. システムプロンプトの調整（オプション）

合成結果の品質を向上させるため、実際の動作を見ながらシステムプロンプトを調整する

## 実装の注意点

1. **バリデーション**
   - 最低2つのプロンプトが選択されていることを確認
   - 選択されたIDが実際に存在するプロンプトであることを確認

2. **エラーハンドリング**
   - API呼び出し失敗時の処理
   - JSONパース失敗時の処理

3. **ユーザビリティ**
   - チェックボックスで複数選択できることを明示
   - 合成結果を編集できることを明示
   - 合成元のプロンプトを表示して、どれを合成したか分かるようにする

4. **パフォーマンス**
   - 大量のプロンプトがある場合のページネーション検討

## 完了条件

- [ ] ルーティング設定完了
- [ ] Promptモデルに`compose_prompts`メソッド実装完了
- [ ] PromptsControllerに`compose`アクション実装完了
- [ ] プロンプト一覧画面更新完了（チェックボックス追加）
- [ ] 合成結果表示フォーム作成完了
- [ ] Promptモデルテスト完了
- [ ] Request specテスト完了
- [ ] ブラウザで動作確認完了

## 今後の拡張案

- 合成履歴の保存（どのプロンプトから合成されたか記録）
- 合成アルゴリズムの選択（単純結合、要約、拡張など）
- 合成プレビュー機能
- 3つ以上のプロンプト合成時の最適化
