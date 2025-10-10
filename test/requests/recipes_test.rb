require "test_helper"

class RecipesTest < ActionDispatch::IntegrationTest
  setup do
    @prompt = Prompt.create!(title: "テストプロンプト", prompt: "テスト内容")
    @recipe = Recipe.create!(
      prompt: @prompt,
      title: "テストレシピ",
      ingredients: "材料A\n材料B",
      instructions: "手順1\n手順2"
    )
  end

  test "show: レシピ詳細が表示される" do
    get recipe_url(@recipe)
    assert_response :success
  end

  test "new: 新規作成フォームが表示される" do
    get new_prompt_recipe_url(@prompt)
    assert_response :success
  end

  test "create: レシピが作成される" do
    assert_difference("Recipe.count", 1) do
      post prompt_recipes_url(@prompt), params: {
        recipe: {
          title: "新しいレシピ",
          ingredients: "材料C",
          instructions: "手順3"
        }
      }
    end
    assert_redirected_to recipe_url(Recipe.last)
  end

  test "create: バリデーションエラー時は再表示される" do
    assert_no_difference("Recipe.count") do
      post prompt_recipes_url(@prompt), params: {
        recipe: {
          title: "",
          ingredients: "",
          instructions: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "edit: 編集フォームが表示される" do
    get edit_recipe_url(@recipe)
    assert_response :success
  end

  test "update: レシピが更新される" do
    patch recipe_url(@recipe), params: {
      recipe: { title: "更新されたタイトル" }
    }
    assert_redirected_to recipe_url(@recipe)
    @recipe.reload
    assert_equal "更新されたタイトル", @recipe.title
  end

  test "update: バリデーションエラー時は再表示される" do
    patch recipe_url(@recipe), params: {
      recipe: { title: "" }
    }
    assert_response :unprocessable_entity
  end

  test "destroy: レシピが削除される" do
    assert_difference("Recipe.count", -1) do
      delete recipe_url(@recipe)
    end
    assert_redirected_to prompt_url(@prompt)
  end

  test "generate: レシピが生成されて保存される" do
    mock_response = {
      "choices" => [{
        "message" => {
          "content" => '{"title":"生成されたレシピ","ingredients":"材料X","instructions":"手順Y"}'
        }
      }]
    }

    @prompt.define_singleton_method(:call_llm_api) { mock_response }

    Prompt.stub(:find, @prompt) do
      assert_difference("Recipe.count", 1) do
        post generate_recipe_prompt_url(@prompt)
      end

      assert_redirected_to recipe_url(Recipe.last)
      assert_equal "生成されたレシピ", Recipe.last.title
      assert_equal "レシピを生成しました。", flash[:notice]
    end
  end

  test "generate: API失敗時にエラーメッセージが表示される" do
    @prompt.define_singleton_method(:call_llm_api) { raise Faraday::Error.new("接続エラー") }

    Prompt.stub(:find, @prompt) do
      assert_no_difference("Recipe.count") do
        post generate_recipe_prompt_url(@prompt)
      end

      assert_redirected_to prompt_url(@prompt)
      assert_match(/エラーが発生しました/, flash[:alert])
    end
  end
end
