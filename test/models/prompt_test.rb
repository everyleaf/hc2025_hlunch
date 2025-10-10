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
end
