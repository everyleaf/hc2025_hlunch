require "rails_helper"

RSpec.describe Prompt, type: :model do
  it "正常な値の場合は有効" do
    prompt = build(:prompt)
    expect(prompt).to be_valid
  end

  it "titleが空の場合は無効" do
    prompt = build(:prompt, title: "")
    expect(prompt).not_to be_valid
    expect(prompt.errors[:title]).to include("can't be blank")
  end

  it "promptが空の場合は無効" do
    prompt = build(:prompt, prompt: "")
    expect(prompt).not_to be_valid
    expect(prompt.errors[:prompt]).to include("can't be blank")
  end

  it "titleが255文字を超える場合は無効" do
    prompt = build(:prompt, title: "a" * 256)
    expect(prompt).not_to be_valid
    expect(prompt.errors[:title]).to include("is too long (maximum is 255 characters)")
  end

  it "titleが255文字の場合は有効" do
    prompt = build(:prompt, title: "a" * 255)
    expect(prompt).to be_valid
  end

  describe "#generate_recipe" do
    let(:prompt) { create(:prompt, prompt: "カレーのレシピを教えてください") }

    it "レシピが正しく生成される" do
      mock_response = {
        "choices" => [ {
          "message" => {
            "content" => '{"title":"カレーライス","ingredients":"玉ねぎ\nにんじん\nじゃがいも","instructions":"野菜を切る\n煮込む\nルーを入れる"}'
          }
        } ]
      }
      allow(prompt).to receive(:call_llm_api).and_return(mock_response)

      recipe = prompt.generate_recipe
      expect(recipe.title).to eq("カレーライス")
      expect(recipe.ingredients).to eq("玉ねぎ\nにんじん\nじゃがいも")
      expect(recipe.instructions).to eq("野菜を切る\n煮込む\nルーを入れる")
      expect(recipe.prompt).to eq(prompt)
      expect(recipe).not_to be_persisted
    end

    it "JSON以外のテキストが含まれていても正しくパースできる" do
      mock_response = {
        "choices" => [ {
          "message" => {
            "content" => '<think>考え中</think>{"title":"テストレシピ","ingredients":"材料A","instructions":"手順1"}'
          }
        } ]
      }
      allow(prompt).to receive(:call_llm_api).and_return(mock_response)

      recipe = prompt.generate_recipe
      expect(recipe.title).to eq("テストレシピ")
      expect(recipe.ingredients).to eq("材料A")
      expect(recipe.instructions).to eq("手順1")
    end

    it "API呼び出し失敗時に例外が発生する" do
      allow(prompt).to receive(:call_llm_api).and_raise(Faraday::Error.new("接続エラー"))

      expect { prompt.generate_recipe }.to raise_error(Faraday::Error)
    end

    it "JSONパース失敗時に例外が発生する" do
      mock_response = {
        "choices" => [ {
          "message" => {
            "content" => "これはJSONではありません"
          }
        } ]
      }
      allow(prompt).to receive(:call_llm_api).and_return(mock_response)

      expect { prompt.generate_recipe }.to raise_error(JSON::ParserError)
    end
  end
end
