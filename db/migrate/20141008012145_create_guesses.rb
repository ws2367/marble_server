class CreateGuesses < ActiveRecord::Migration
  def change
    create_table :guesses do |t|
      t.belongs_to :quiz
      t.belongs_to :user
      t.string  :answer
      t.timestamps
    end
  end
end
