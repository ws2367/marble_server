class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.integer :friend_fb_id, :limit => 8
      t.belongs_to :user

      t.timestamps
    end
    add_index :friendships, :friend_fb_id
    add_index :friendships, :user_id
  end
end
