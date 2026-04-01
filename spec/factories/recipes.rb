FactoryBot.define do
  factory :recipe do
    association :prompt
    title { "テストレシピ" }
    ingredients { "材料A\n材料B" }
    instructions { "手順1\n手順2" }
  end
end
