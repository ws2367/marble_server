class AddStatusesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :statuses, :text
  end
end
