class AddNamesToQuizzes < ActiveRecord::Migration
  def change
    add_column :quizzes, :author_name,  :string
    add_column :quizzes, :option0_name, :string
    add_column :quizzes, :option1_name, :string
  end
end
