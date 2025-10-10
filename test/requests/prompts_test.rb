require "test_helper"

class PromptsTest < ActionDispatch::IntegrationTest
  setup do
    @prompt = Prompt.create!(title: "テストプロンプト", prompt: "これはテストです")
  end

  test "index: プロンプト一覧が表示される" do
    get prompts_url
    assert_response :success
  end

  test "show: プロンプト詳細が表示される" do
    get prompt_url(@prompt)
    assert_response :success
  end

  test "new: 新規作成フォームが表示される" do
    get new_prompt_url
    assert_response :success
  end

  test "create: プロンプトが作成される" do
    assert_difference("Prompt.count", 1) do
      post prompts_url, params: { prompt: { title: "新しいプロンプト", prompt: "新しい内容" } }
    end
    assert_redirected_to prompt_url(Prompt.last)
  end

  test "create: バリデーションエラー時は再表示される" do
    assert_no_difference("Prompt.count") do
      post prompts_url, params: { prompt: { title: "", prompt: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "edit: 編集フォームが表示される" do
    get edit_prompt_url(@prompt)
    assert_response :success
  end

  test "update: プロンプトが更新される" do
    patch prompt_url(@prompt), params: { prompt: { title: "更新されたタイトル" } }
    assert_redirected_to prompt_url(@prompt)
    @prompt.reload
    assert_equal "更新されたタイトル", @prompt.title
  end

  test "update: バリデーションエラー時は再表示される" do
    patch prompt_url(@prompt), params: { prompt: { title: "" } }
    assert_response :unprocessable_entity
  end

  test "destroy: プロンプトが削除される" do
    assert_difference("Prompt.count", -1) do
      delete prompt_url(@prompt)
    end
    assert_redirected_to prompts_url
  end
end
