class Prompt < ApplicationRecord
  has_many :recipes, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :prompt, presence: true
end
