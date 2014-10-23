class AddKeyword123ToKeywordUpdates < ActiveRecord::Migration
  def change
    add_column :keyword_updates, :keyword1, :string
    add_column :keyword_updates, :keyword2, :string
    add_column :keyword_updates, :keyword3, :string
    remove_column :keyword_updates, :added
  end
end
