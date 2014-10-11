class AddKeywordToKeywords < ActiveRecord::Migration
  def change
    add_column :keywords, :keyword, :string
  end
end
