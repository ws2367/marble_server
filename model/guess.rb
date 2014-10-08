# == Schema Information
#
# Table name: guesses
#
#  id         :integer          not null, primary key
#  quiz_id    :integer
#  user_id    :integer
#  answer     :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Guess < ActiveRecord::Base
  belongs_to :user
  belongs_to :quiz
  
  # update compare_num of the quiz
  after_create {
    self.quiz.with_lock do 
      self.quiz.update_attribute("compare_num", self.quiz.compare_num.to_i + 1)
    end
  }
end
