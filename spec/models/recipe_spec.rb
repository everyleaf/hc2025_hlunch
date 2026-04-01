require "rails_helper"

RSpec.describe Recipe, type: :model do
  let(:prompt) { create(:prompt) }

  it "正常な値の場合は有効" do
    recipe = build(:recipe, prompt: prompt)
    expect(recipe).to be_valid
  end

  it "titleが空の場合は無効" do
    recipe = build(:recipe, prompt: prompt, title: "")
    expect(recipe).not_to be_valid
    expect(recipe.errors[:title]).to include("can't be blank")
  end

  it "ingredientsが空の場合は無効" do
    recipe = build(:recipe, prompt: prompt, ingredients: "")
    expect(recipe).not_to be_valid
    expect(recipe.errors[:ingredients]).to include("can't be blank")
  end

  it "instructionsが空の場合は無効" do
    recipe = build(:recipe, prompt: prompt, instructions: "")
    expect(recipe).not_to be_valid
    expect(recipe.errors[:instructions]).to include("can't be blank")
  end

  it "titleが255文字を超える場合は無効" do
    recipe = build(:recipe, prompt: prompt, title: "a" * 256)
    expect(recipe).not_to be_valid
    expect(recipe.errors[:title]).to include("is too long (maximum is 255 characters)")
  end

  it "titleが255文字の場合は有効" do
    recipe = build(:recipe, prompt: prompt, title: "a" * 255)
    expect(recipe).to be_valid
  end

  it "promptに紐づいている" do
    recipe = build(:recipe, prompt: prompt)
    expect(recipe.prompt).to eq(prompt)
  end

  it "prompt_idがnilの場合は無効" do
    recipe = build(:recipe, prompt: nil)
    expect(recipe).not_to be_valid
  end
end
