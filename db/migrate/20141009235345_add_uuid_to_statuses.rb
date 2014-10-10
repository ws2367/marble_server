class AddUuidToStatuses < ActiveRecord::Migration
  def change
    add_column :statuses, :uuid, :string
  end
end
