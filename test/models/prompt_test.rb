require "test_helper"

class PromptTest < ActiveSupport::TestCase
  test "正常な値の場合は有効" do
    prompt = Prompt.new(title: "テストプロンプト", prompt: "これはテストです")
    assert prompt.valid?
  end

  test "titleが空の場合は無効" do
    prompt = Prompt.new(title: "", prompt: "これはテストです")
    assert_not prompt.valid?
    assert_includes prompt.errors[:title], "can't be blank"
  end

  test "promptが空の場合は無効" do
    prompt = Prompt.new(title: "テストプロンプト", prompt: "")
    assert_not prompt.valid?
    assert_includes prompt.errors[:prompt], "can't be blank"
  end

  test "titleが255文字を超える場合は無効" do
    prompt = Prompt.new(title: "a" * 256, prompt: "これはテストです")
    assert_not prompt.valid?
    assert_includes prompt.errors[:title], "is too long (maximum is 255 characters)"
  end

  test "titleが255文字の場合は有効" do
    prompt = Prompt.new(title: "a" * 255, prompt: "これはテストです")
    assert prompt.valid?
  end

  test "generate_recipe: レシピが正しく生成される" do
    prompt = Prompt.create!(title: "テストプロンプト", prompt: "カレーのレシピを教えてください")

    mock_response = {
      "choices" => [{
        "message" => {
          "content" => '{"title":"カレーライス","ingredients":"玉ねぎ\nにんじん\nじゃがいも","instructions":"野菜を切る\n煮込む\nルーを入れる"}'
        }
      }]
    }

    prompt.stub(:call_llm_api, mock_response) do
      recipe = prompt.generate_recipe
      assert_equal "カレーライス", recipe.title
      assert_equal "玉ねぎ\nにんじん\nじゃがいも", recipe.ingredients
      assert_equal "野菜を切る\n煮込む\nルーを入れる", recipe.instructions
      assert_equal prompt, recipe.prompt
      assert_not recipe.persisted?
    end
  end

  test "generate_recipe: JSON以外のテキストが含まれていても正しくパースできる" do
    prompt = Prompt.create!(title: "テストプロンプト", prompt: "レシピ")

    mock_response = {
      "choices" => [{
        "message" => {
          "content" => '<think>考え中</think>{"title":"テストレシピ","ingredients":"材料A","instructions":"手順1"}'
        }
      }]
    }

    prompt.stub(:call_llm_api, mock_response) do
      recipe = prompt.generate_recipe
      assert_equal "テストレシピ", recipe.title
      assert_equal "材料A", recipe.ingredients
      assert_equal "手順1", recipe.instructions
    end
  end

  test "generate_recipe: API呼び出し失敗時に例外が発生する" do
    prompt = Prompt.create!(title: "テストプロンプト", prompt: "レシピ")

    prompt.stub(:call_llm_api, -> { raise Faraday::Error.new("接続エラー") }) do
      assert_raises(Faraday::Error) do
        prompt.generate_recipe
      end
    end
  end

  test "generate_recipe: JSONパース失敗時に例外が発生する" do
    prompt = Prompt.create!(title: "テストプロンプト", prompt: "レシピ")

    mock_response = {
      "choices" => [{
        "message" => {
          "content" => "これはJSONではありません"
        }
      }]
    }

    prompt.stub(:call_llm_api, mock_response) do
      assert_raises(JSON::ParserError) do
        prompt.generate_recipe
      end
    end
  end
end
