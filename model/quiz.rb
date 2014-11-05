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
#  keyword_id   :integer
#  popularity   :float            default(0.0)
#

class Quiz < ActiveRecord::Base
  serialize :comments
  has_many :guesses, inverse_of: :quiz
  belongs_to :user, foreign_key: "author", primary_key: :fb_id, inverse_of: :quizzes

  after_create {
    self.update_attribute("comments",[])
    self.update_attribute("popularity", (self.created_at.to_f - POPULARITY_BASE) * 2)
  }

  self.per_page = 20

  def self.about_keyword(keyword)
    return where("keyword = ?", keyword)
  end

  def self.about_friends_of user
    Quiz.joins('INNER JOIN friendships ON (friendships.friend_fb_id = quizzes.option0 OR '\
                                          'friendships.friend_fb_id = quizzes.option1 OR '\
                                          'friendships.friend_fb_id = quizzes.author) AND '\
                                          'friendships.user_id = %d' % user.id).distinct
  end

  def self.about_user(fb_id)
    return where("option0 = ? OR option1 = ? OR author = ?", fb_id, fb_id, fb_id)
  end

  def self.map_to_respond(quizzes, user)
    quizzes.map{|q|
     p = q.attributes
     p.delete("updated_at")
     p.delete("keyword_id")
     p.delete("id")
     p["answered_before"] = q.answered_before(user)
     p["option0_num"] = q.calculate_option0_num
     p["option1_num"] = q.calculate_option1_num
     p
    }
  end

  def calculate_option0_num
    self.guesses.where(answer: self.option0_name).count
  end

  def calculate_option1_num 
    self.guesses.where(answer: self.option1_name).count
  end

  def answered_before user
    guess = user.guesses.find_by_quiz_id(self.id)
    if guess == nil
      return nil 
    else
      return guess.answer
    end
  end

  # def user
  #   return User.find_by_fb_id(self.author)
  # end
  
  def self.insert_comment post_uuid, user, comment, uuid
    quiz = Quiz.find_by_uuid(post_uuid)
    if quiz != nil
      quiz.comments << {fb_id: user.fb_id, name:user.name, uuid: uuid, 
                        comment: comment, time: Time.now}
      
      subtrahend = (quiz.comments.count > 1 ? quiz.comments.last(2)[0][:time].to_f :
                                              quiz.created_at.to_f)
      quiz.popularity = quiz.popularity.to_f - subtrahend + quiz.comments.last[:time].to_f + 300.0
      quiz.save
      return quiz
    else
      return nil
    end
  end

  def self.create_quiz_dependencies hash, user
    keyword = Keyword.find_or_create hash[:keyword], user

    option0 = User.find_or_create hash[:option0], hash[:option0_name]
    option1 = User.find_or_create hash[:option1], hash[:option1_name]

    q = Quiz.create(author: user.fb_id, 
                    author_name: hash[:author_name], 
                    keyword_id: keyword.id, 
                    keyword: keyword.keyword,
                    option0: hash[:option0], 
                    option0_name: hash[:option0_name],
                    option1: hash[:option1],  
                    option1_name: hash[:option1_name],
                    answer:  hash[:answer],
                    uuid:    hash[:uuid])

    answer = (hash[:answer] == hash[:option0_name]) ? option0 : option1
    rank = Rank.find_or_create(keyword, answer)
    rank.increment_score
    return [option0, option1, q]
  end

  # popularity = tc + tp + nc*300 + nf*150
  # tc: creation time of the last comment
  # tp: creation time of the post
  # nc: # of comments
  # nf: # of follows
  # POPULARITY_BASE: Tue, 01 Apr 2014 00:00:00 GMT
  
  # after_create {
  #   self.with_lock do
  #     self.update_attribute("popularity", (self.created_at.to_f - POPULARITY_BASE) * 2)
  #   end
  # }
end
