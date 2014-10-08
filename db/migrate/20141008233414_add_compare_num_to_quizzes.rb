class AddCompareNumToQuizzes < ActiveRecord::Migration
  def change
    add_column :quizzes, :compare_num, :integer
  end
end
