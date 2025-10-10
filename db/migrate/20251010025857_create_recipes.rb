class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.references :prompt, null: false, foreign_key: true
      t.string :title
      t.text :ingredients
      t.text :instructions

      t.timestamps
    end
  end
end
