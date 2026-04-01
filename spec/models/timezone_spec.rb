require "rails_helper"

RSpec.describe "タイムゾーン設定" do
  it "Time.current がJST (+09:00) を返す" do
    expect(Time.current.utc_offset).to eq(9 * 3600)
  end

  describe "Promptのcreated_at" do
    let(:prompt) { create(:prompt) }

    it "created_at はJSTで返る" do
      expect(prompt.created_at.utc_offset).to eq(9 * 3600)
    end

    it "DBにはUTCで保存される" do
      prompt
      raw = ActiveRecord::Base.connection.select_value(
        "SELECT created_at FROM prompts WHERE id = #{prompt.id}"
      )
      # SQLiteはUTCの文字列で保存される（タイムゾーン情報なし）
      expect(raw).not_to include("+09")
    end
  end
end
