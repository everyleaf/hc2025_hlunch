class Prompt < ApplicationRecord
  has_many :recipes, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :prompt, presence: true

  def generate_recipe
    response = call_llm_api
    recipe_attrs = parse_llm_response(response)
    recipes.build(recipe_attrs)
  end

  # 複数のプロンプトをLLMで合成
  # @param prompt_ids [Array<Integer>] 合成するプロンプトのIDの配列
  # @return [Hash] { title: String, prompt: String }
  def self.compose_prompts(prompt_ids)
    prompts = where(id: prompt_ids).order(:id)
    raise ArgumentError, "少なくとも2つのプロンプトを選択してください" if prompts.count < 2

    response = call_compose_llm_api(prompts)
    parse_compose_response(response)
  end

  private

  def call_llm_api
    client = OpenAI::Client.new
    client.chat(
      parameters: {
        model: "gpt-5-mini",
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
    Rails.logger.info("LLM Response Content: #{content}")

    # JSONブロックを抽出（```json ... ``` または { ... } の形式）
    json_str = if content =~ /```json\s*(\{.*?\})\s*```/m
      $1
    elsif content =~ /(\{.*\})/m
      $1
    else
      content
    end

    Rails.logger.info("Extracted JSON String: #{json_str}")

    json_data = JSON.parse(json_str)

    {
      title: json_data["title"],
      ingredients: json_data["ingredients"],
      instructions: json_data["instructions"]
    }
  end

  # プロンプト合成用のクラスメソッド（private）
  def self.call_compose_llm_api(prompts)
    client = OpenAI::Client.new
    begin
      client.chat(
        parameters: {
          model: "gpt-5-mini",
          messages: [
            { role: "system", content: compose_system_prompt },
            { role: "user", content: build_compose_user_prompt(prompts) }
          ]
        }
      )
    rescue => e
      Rails.logger.error("OpenAI API Error: #{e.class} - #{e.message}")
      Rails.logger.error("Error details: #{e.inspect}") if e.respond_to?(:response)
      raise
    end
  end

  def self.compose_system_prompt
    <<~PROMPT
      あなたは複数のレシピ生成用プロンプトを分析して、それらを統合した新しいプロンプトを生成するアシスタントです。

      入力された複数のプロンプトはすべてレシピ生成のためのものです。
      それぞれのプロンプトの意図（料理の種類、調理法、特徴など）を理解し、それらの要素を自然に組み合わせた新しいレシピ生成用プロンプトを作成してください。

      レスポンスは以下のJSON形式で返してください：

      {
        "title": "合成されたプロンプトのタイトル",
        "prompt": "合成されたプロンプト本文"
      }

      重要：
      - 各プロンプトの核心的な要素（料理のジャンル、調理法、特徴、制約など）を抽出して組み合わせること
      - 矛盾する要素がある場合は自然に調和させること
      - レシピ生成の文脈を保つこと
      - 自然で分かりやすい日本語にすること
      - 冗長にならないよう簡潔にまとめること
    PROMPT
  end

  def self.build_compose_user_prompt(prompts)
    prompt_list = prompts.map.with_index(1) do |p, i|
      "プロンプト#{i}:\nタイトル: #{p.title}\n内容: #{p.prompt}"
    end.join("\n\n")

    <<~PROMPT
      以下のプロンプトを合成してください：

      #{prompt_list}
    PROMPT
  end

  def self.parse_compose_response(response)
    content = response.dig("choices", 0, "message", "content")
    Rails.logger.info("LLM Compose Response Content: #{content}")

    # <think>タグを除去
    content = content.gsub(/<think>.*?<\/think>/m, '')

    # JSONブロックを抽出
    json_str = if content =~ /```json\s*(\{.*?\})\s*```/m
      $1
    elsif content =~ /(\{.*\})/m
      $1
    else
      content
    end

    Rails.logger.info("Extracted Compose JSON String: #{json_str}")

    json_data = JSON.parse(json_str)

    {
      title: json_data["title"],
      prompt: json_data["prompt"]
    }
  end

  private_class_method :call_compose_llm_api, :compose_system_prompt, :build_compose_user_prompt, :parse_compose_response
end
