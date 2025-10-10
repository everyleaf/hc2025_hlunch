class Prompt < ApplicationRecord
  has_many :recipes, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :prompt, presence: true

  def generate_recipe
    response = call_llm_api
    recipe_attrs = parse_llm_response(response)
    recipes.build(recipe_attrs)
  end

  private

  def call_llm_api
    client = OpenAI::Client.new
    client.chat(
      parameters: {
        model: "local-model",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      }
    )
  end

  def system_prompt
    <<~PROMPT
      以下のプロンプトに基づいてレシピを生成してください。
      レスポンスは以下のJSON形式で返してください：

      {
        "title": "レシピのタイトル",
        "ingredients": "材料のリスト（改行区切り）",
        "instructions": "作り方の手順（改行区切り）"
      }
    PROMPT
  end

  def parse_llm_response(response)
    content = response.dig("choices", 0, "message", "content")

    # JSONブロックを抽出（```json ... ``` または { ... } の形式）
    json_str = if content =~ /```json\s*(\{.*?\})\s*```/m
      $1
    elsif content =~ /(\{.*\})/m
      $1
    else
      content
    end

    json_data = JSON.parse(json_str)

    {
      title: json_data["title"],
      ingredients: json_data["ingredients"],
      instructions: json_data["instructions"]
    }
  end
end
