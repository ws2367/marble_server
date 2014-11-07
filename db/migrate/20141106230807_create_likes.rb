class CreateLikes < ActiveRecord::Migration
  def change
    create_table :likes do |t|
      t.belongs_to :user
      t.integer    :likee_id
      t.belongs_to :keyword
      t.timestamps
    end
  end
end
