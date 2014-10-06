class CreateQuizzes < ActiveRecord::Migration
  def change
      create_table :quizzes do |t|
      t.string  :author
      t.string  :keyword
      t.string  :option0
      t.string  :option1
      t.string  :answer
      t.string  :uuid
      t.timestamps
    end
  end
end
