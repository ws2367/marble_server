# == Schema Information
#
# Table name: quizzes
#
#  id           :integer          not null, primary key
#  author       :string(255)
#  keyword      :string(255)
#  option0      :string(255)
#  option1      :string(255)
#  answer       :string(255)
#  uuid         :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  comments     :text
#  author_name  :string(255)
#  option0_name :string(255)
#  option1_name :string(255)
#  compare_num  :integer
#

class Quiz < ActiveRecord::Base
  serialize :comments
  has_many :guesses, inverse_of: :quiz
  # def initialize quiz
  #   @uuid    = UUIDTools::UUID.random_create.to_s
  #   @author  = quiz["author"]
  #   @keyword = quiz["keyword"]
  #   @option0 = quiz["option0"]
  #   @option1 = quiz["option1"]
  #   @time    = Time.now
  #   # @@quizzes << self
  # end

  after_create {
    self.update_attribute("comments",[])
  }

  before_save :default_compare_num
  def default_compare_num
    self.compare_num ||= 0
  end

  def self.insert_comment post_uuid, user, comment
    quiz = Quiz.find_by_uuid(post_uuid)
    if quiz != nil
      quiz.comments << {fb_id: user.fb_id, name:user.name, 
                        comment: comment, time: Time.now}
      quiz.save
      return true
    else
      return false
    end
  end

  # popularity = tc + tp + nc*300 + nf*150
  # tc: creation time of the last comment
  # tp: creation time of the post
  # nc: # of comments
  # nf: # of follows
  # POPULARITY_BASE: Tue, 01 Apr 2014 00:00:00 GMT
  POPULARITY_BASE = 1396310400.0
  
  # after_create {
  #   self.with_lock do
  #     self.update_attribute("popularity", (self.created_at.to_f - POPULARITY_BASE) * 2)
  #   end
  # }
end
