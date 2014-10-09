class CreateStatuses < ActiveRecord::Migration
  def change
    create_table :statuses do |t|
      t.belongs_to :user
      t.string  :status
      t.text    :comments
      t.timestamps
    end

    remove_column :users, :statuses
  end
end