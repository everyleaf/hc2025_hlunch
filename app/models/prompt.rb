class Prompt < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :prompt, presence: true
end
