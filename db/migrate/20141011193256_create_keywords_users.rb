class CreateKeywordsUsers < ActiveRecord::Migration
  def change
    create_table :keywords_users, id: false do |t|
      t.integer :user_id
      t.integer :keyword_id
    end
  end
end
