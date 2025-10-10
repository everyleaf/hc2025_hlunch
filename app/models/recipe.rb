class Recipe < ApplicationRecord
  belongs_to :prompt

  validates :title, presence: true, length: { maximum: 255 }
  validates :ingredients, presence: true
  validates :instructions, presence: true
  validates :prompt_id, presence: true
end
