class CreateRanks < ActiveRecord::Migration
  def change
    create_table :ranks do |t|
      t.belongs_to :user
      t.belongs_to :keyword
      t.integer    :score
      t.timestamps
    end
  end
end
