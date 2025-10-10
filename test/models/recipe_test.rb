require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  setup do
    @prompt = Prompt.create!(title: "テストプロンプト", prompt: "テスト内容")
  end

  test "正常な値の場合は有効" do
    recipe = Recipe.new(
      prompt: @prompt,
      title: "テストレシピ",
      ingredients: "材料A\n材料B",
      instructions: "手順1\n手順2"
    )
    assert recipe.valid?
  end

  test "titleが空の場合は無効" do
    recipe = Recipe.new(
      prompt: @prompt,
      title: "",
      ingredients: "材料A",
      instructions: "手順1"
    )
    assert_not recipe.valid?
    assert_includes recipe.errors[:title], "can't be blank"
  end

  test "ingredientsが空の場合は無効" do
    recipe = Recipe.new(
      prompt: @prompt,
      title: "テストレシピ",
      ingredients: "",
      instructions: "手順1"
    )
    assert_not recipe.valid?
    assert_includes recipe.errors[:ingredients], "can't be blank"
  end

  test "instructionsが空の場合は無効" do
    recipe = Recipe.new(
      prompt: @prompt,
      title: "テストレシピ",
      ingredients: "材料A",
      instructions: ""
    )
    assert_not recipe.valid?
    assert_includes recipe.errors[:instructions], "can't be blank"
  end

  test "titleが255文字を超える場合は無効" do
    recipe = Recipe.new(
      prompt: @prompt,
      title: "a" * 256,
      ingredients: "材料A",
      instructions: "手順1"
    )
    assert_not recipe.valid?
    assert_includes recipe.errors[:title], "is too long (maximum is 255 characters)"
  end

  test "titleが255文字の場合は有効" do
    recipe = Recipe.new(
      prompt: @prompt,
      title: "a" * 255,
      ingredients: "材料A",
      instructions: "手順1"
    )
    assert recipe.valid?
  end

  test "promptに紐づいている" do
    recipe = Recipe.new(
      prompt: @prompt,
      title: "テストレシピ",
      ingredients: "材料A",
      instructions: "手順1"
    )
    assert_equal @prompt, recipe.prompt
  end

  test "prompt_idがnilの場合は無効" do
    recipe = Recipe.new(
      prompt: nil,
      title: "テストレシピ",
      ingredients: "材料A",
      instructions: "手順1"
    )
    assert_not recipe.valid?
  end
end
