class RemoveCompareNumFromQuizzes < ActiveRecord::Migration
  def change
    remove_column :quizzes, :compare_num
  end
end
