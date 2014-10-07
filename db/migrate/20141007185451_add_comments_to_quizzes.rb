class AddCommentsToQuizzes < ActiveRecord::Migration
  def change
    add_column :quizzes, :comments, :text
  end
end
