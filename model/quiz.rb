# == Schema Information
#
# Table name: quizzes
#
#  id         :integer          not null, primary key
#  author     :string(255)
#  keyword    :string(255)
#  option0    :string(255)
#  option1    :string(255)
#  answer     :string(255)
#  uuid       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Quiz < ActiveRecord::Base

  # def initialize quiz
  #   @uuid    = UUIDTools::UUID.random_create.to_s
  #   @author  = quiz["author"]
  #   @keyword = quiz["keyword"]
  #   @option0 = quiz["option0"]
  #   @option1 = quiz["option1"]
  #   @time    = Time.now
  #   # @@quizzes << self
  # end

  
end
