require "rails_helper"

RSpec.describe "Prompts", type: :request do
  let!(:prompt) { create(:prompt) }

  describe "GET /prompts" do
    it "プロンプト一覧が表示される" do
      get prompts_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /prompts/:id" do
    it "プロンプト詳細が表示される" do
      get prompt_path(prompt)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /prompts/new" do
    it "新規作成フォームが表示される" do
      get new_prompt_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /prompts" do
    it "プロンプトが作成される" do
      expect {
        post prompts_path, params: { prompt: { title: "新しいプロンプト", prompt: "新しい内容" } }
      }.to change(Prompt, :count).by(1)
      expect(response).to redirect_to(prompt_path(Prompt.last))
    end

    it "バリデーションエラー時は再表示される" do
      expect {
        post prompts_path, params: { prompt: { title: "", prompt: "" } }
      }.not_to change(Prompt, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /prompts/:id/edit" do
    it "編集フォームが表示される" do
      get edit_prompt_path(prompt)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /prompts/:id" do
    it "プロンプトが更新される" do
      patch prompt_path(prompt), params: { prompt: { title: "更新されたタイトル" } }
      expect(response).to redirect_to(prompt_path(prompt))
      expect(prompt.reload.title).to eq("更新されたタイトル")
    end

    it "バリデーションエラー時は再表示される" do
      patch prompt_path(prompt), params: { prompt: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /prompts/:id" do
    it "プロンプトが削除される" do
      expect {
        delete prompt_path(prompt)
      }.to change(Prompt, :count).by(-1)
      expect(response).to redirect_to(prompts_path)
    end
  end
end
