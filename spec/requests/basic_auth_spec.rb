require "rails_helper"

RSpec.describe "BASIC認証", type: :request do
  context "BASIC_AUTH_USERNAME/BASIC_AUTH_PASSWORDが設定されている場合" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("BASIC_AUTH_USERNAME").and_return("testuser")
      allow(ENV).to receive(:[]).with("BASIC_AUTH_PASSWORD").and_return("testpass")
    end

    it "認証なしでアクセスすると401が返る" do
      get prompts_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "正しい認証情報でアクセスすると200が返る" do
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials("testuser", "testpass")
      get prompts_path, headers: { "HTTP_AUTHORIZATION" => credentials }
      expect(response).to have_http_status(:success)
    end

    it "誤った認証情報では401が返る" do
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials("wrong", "wrong")
      get prompts_path, headers: { "HTTP_AUTHORIZATION" => credentials }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
