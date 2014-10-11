class CreateKeywordUpdates < ActiveRecord::Migration
  def change
    create_table :keyword_updates do |t|
      t.belongs_to :user
      t.text   :added
      t.text   :removed
      t.text   :comments
      t.string :uuid
      t.timestamps
    end
  end
end
