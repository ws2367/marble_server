class AddKeywordIdToQuizzes < ActiveRecord::Migration
  def change
    add_column :quizzes, :keyword_id, :integer
  end
end
