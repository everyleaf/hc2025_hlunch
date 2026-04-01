# Minitest → RSpec 移行計画

## Context

Issue #7: テストフレームワークがMinitestだが、ドキュメントやディレクトリ名に「request spec」などRSpec風の用語が混在している。RSpecへの移行で解消する。

現在のテスト: モデルテスト2ファイル(16テスト) + リクエストテスト2ファイル(20テスト) = 計36テスト。規模が小さいため一括移行が可能。

## 追加するGem

`Gemfile` の `group :development, :test` に追加:
- `rspec-rails` (~> 7.1)
- `factory_bot_rails` (~> 6.4)

理由: 既存テストはfixturesを参照せず `create!` でデータ作成しており、FactoryBotがこのパターンに合う。rubocop-rspecは追加しない（rubocop-rails-omakaseとの競合回避）。

## 実装ステップ

### Step 1: Gem追加 & RSpecセットアップ
- `Gemfile` に gem 追加 → `bundle install`
- `rails generate rspec:install` で `.rspec`, `spec/spec_helper.rb`, `spec/rails_helper.rb` 生成
- `spec/rails_helper.rb` に FactoryBot 設定追加 (`config.include FactoryBot::Syntax::Methods`)
- `spec/factories/prompts.rb`, `spec/factories/recipes.rb` 作成
- **コミット**

### Step 2: モデルspec変換
- `test/models/recipe_test.rb` → `spec/models/recipe_spec.rb` (8テスト、純粋なバリデーション)
- `test/models/prompt_test.rb` → `spec/models/prompt_spec.rb` (8テスト、stub変換あり)
- `bundle exec rspec spec/models/` で通ること確認
- **コミット**

主な変換パターン:
| Minitest | RSpec |
|---|---|
| `assert prompt.valid?` | `expect(prompt).to be_valid` |
| `assert_not prompt.valid?` | `expect(prompt).not_to be_valid` |
| `assert_includes errors[:x], "..."` | `expect(errors[:x]).to include("...")` |
| `assert_equal expected, actual` | `expect(actual).to eq(expected)` |
| `assert_raises(Err) { }` | `expect { }.to raise_error(Err)` |
| `obj.stub(:method, val) { }` | `allow(obj).to receive(:method).and_return(val)` |
| `stub(:m, -> { raise E }) { }` | `allow(obj).to receive(:m).and_raise(E)` |

### Step 3: リクエストspec変換
- `test/requests/prompts_test.rb` → `spec/requests/prompts_spec.rb` (9テスト)
- `test/requests/recipes_test.rb` → `spec/requests/recipes_spec.rb` (11テスト)
- `bundle exec rspec` で全36テスト通ること確認
- **コミット**

追加の変換パターン:
| Minitest | RSpec |
|---|---|
| `assert_response :success` | `expect(response).to have_http_status(:success)` |
| `assert_redirected_to url` | `expect(response).to redirect_to(path)` |
| `assert_difference("M.count", 1) { }` | `expect { }.to change(M, :count).by(1)` |
| `assert_no_difference("M.count") { }` | `expect { }.not_to change(M, :count)` |

generateテストのmock変換（最も複雑な箇所）:
```ruby
# 元: Prompt.stub(:find, @prompt) + define_singleton_method
# 新: allow(Prompt).to receive(:find).and_return(prompt) + allow(prompt).to receive(:call_llm_api).and_return(mock_response)
```

### Step 4: CI・ドキュメント更新 & 旧テスト削除
- `.github/workflows/ci.yml`: `bin/rails db:test:prepare test test:system` → `bin/rails db:test:prepare && bundle exec rspec`
- `.claude/CLAUDE.md`: テストコマンド・ディレクトリパスをRSpec用に更新
- `test/` ディレクトリ全体を削除
- 最終確認: `bundle exec rspec --format documentation` と `rubocop`
- **コミット**

## 注意点
- `call_llm_api` はprivateメソッドだが、`allow(concrete_object)` でstub可能（`instance_double`は使わない）
- flash確認はredirect後に `follow_redirect!` してから確認する場合がある
- `Prompt.find` のstubでは引数が文字列（Railsのparams経由）なので `.with(prompt.id.to_s)` にするか、引数指定なしにする

## 変更対象ファイル一覧

**変更:**
- `Gemfile`
- `.github/workflows/ci.yml`
- `.claude/CLAUDE.md`

**新規作成:**
- `.rspec`
- `spec/spec_helper.rb`
- `spec/rails_helper.rb`
- `spec/factories/prompts.rb`
- `spec/factories/recipes.rb`
- `spec/models/prompt_spec.rb`
- `spec/models/recipe_spec.rb`
- `spec/requests/prompts_spec.rb`
- `spec/requests/recipes_spec.rb`

**削除:**
- `test/` ディレクトリ全体

## 検証方法
1. `bundle exec rspec --format documentation` → 36 examples, 0 failures
2. `bundle exec rubocop` → 新規violation なし
3. PRを出してCIが通ること確認
