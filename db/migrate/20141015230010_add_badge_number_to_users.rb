class AddBadgeNumberToUsers < ActiveRecord::Migration
  def change
    add_column :users, :badge_number, :integer, default: 0
  end
end
