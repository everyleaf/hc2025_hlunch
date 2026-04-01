require "rails_helper"

RSpec.describe "Recipes", type: :request do
  let!(:prompt) { create(:prompt) }
  let!(:recipe) { create(:recipe, prompt: prompt) }

  describe "GET /recipes/:id" do
    it "レシピ詳細が表示される" do
      get recipe_path(recipe)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /prompts/:prompt_id/recipes/new" do
    it "新規作成フォームが表示される" do
      get new_prompt_recipe_path(prompt)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /prompts/:prompt_id/recipes" do
    it "レシピが作成される" do
      expect {
        post prompt_recipes_path(prompt), params: {
          recipe: { title: "新しいレシピ", ingredients: "材料C", instructions: "手順3" }
        }
      }.to change(Recipe, :count).by(1)
      expect(response).to redirect_to(recipe_path(Recipe.last))
    end

    it "バリデーションエラー時は再表示される" do
      expect {
        post prompt_recipes_path(prompt), params: {
          recipe: { title: "", ingredients: "", instructions: "" }
        }
      }.not_to change(Recipe, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /recipes/:id/edit" do
    it "編集フォームが表示される" do
      get edit_recipe_path(recipe)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /recipes/:id" do
    it "レシピが更新される" do
      patch recipe_path(recipe), params: { recipe: { title: "更新されたタイトル" } }
      expect(response).to redirect_to(recipe_path(recipe))
      expect(recipe.reload.title).to eq("更新されたタイトル")
    end

    it "バリデーションエラー時は再表示される" do
      patch recipe_path(recipe), params: { recipe: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /recipes/:id" do
    it "レシピが削除される" do
      expect {
        delete recipe_path(recipe)
      }.to change(Recipe, :count).by(-1)
      expect(response).to redirect_to(prompt_path(prompt))
    end
  end

  describe "POST /prompts/:id/generate_recipe" do
    it "レシピが生成されて保存される" do
      mock_response = {
        "choices" => [ {
          "message" => {
            "content" => '{"title":"生成されたレシピ","ingredients":"材料X","instructions":"手順Y"}'
          }
        } ]
      }
      allow(Prompt).to receive(:find).and_return(prompt)
      allow(prompt).to receive(:call_llm_api).and_return(mock_response)

      expect {
        post generate_recipe_prompt_path(prompt)
      }.to change(Recipe, :count).by(1)

      expect(response).to redirect_to(recipe_path(Recipe.last))
      expect(Recipe.last.title).to eq("生成されたレシピ")
      follow_redirect!
      expect(flash[:notice]).to eq("レシピを生成しました。")
    end

    it "API失敗時にエラーメッセージが表示される" do
      allow(Prompt).to receive(:find).and_return(prompt)
      allow(prompt).to receive(:call_llm_api).and_raise(Faraday::Error.new("接続エラー"))

      expect {
        post generate_recipe_prompt_path(prompt)
      }.not_to change(Recipe, :count)

      expect(response).to redirect_to(prompt_path(prompt))
      follow_redirect!
      expect(flash[:alert]).to match(/エラーが発生しました/)
    end
  end
end
