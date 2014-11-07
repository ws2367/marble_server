# == Schema Information
#
# Table name: users
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  fb_id        :string(255)
#  access_token :string(255)
#  logins       :text
#  device_token :string(255)
#  badge_number :integer          default(0)
#

class User < ActiveRecord::Base
  attr_accessor :current_user

  serialize :logins
  has_many :statuses, inverse_of: :user
  has_many :guesses,  inverse_of: :user
  has_many :keywords, inverse_of: :user
  has_many :ranks,    inverse_of: :user
  has_many :quizzes,  inverse_of: :user
  has_many :keyword_updates, inverse_of: :user
  
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships, :source => 'friends'

  has_and_belongs_to_many :profile_keywords, class_name: "Keyword"
  has_many :likes, inverse_of: :user

  # attr_accessor :name, :fb_id, :access_token, :friends, :fb_friends, :options
  # @@users = []

  #
  #=========Class method============
  #
  # def self.find_by_fb_id fb_id
  #   selected = @@users.select{|user| user.fb_id == fb_id}
  #   if selected.count == 1
  #     return selected[0]
  #   else
  #     return nil
  #   end
  # end

  # def self.find_by_access_token token
  #   selected = @@users.select{|user| user.access_token == token}
  #   if selected.count == 1
  #     return selected[0]
  #   else
  #     return nil
  #   end
  # end
  
  def like_a_keyword user_fb_id, keyword_string
    likee = User.find_by_fb_id(user_fb_id)
    keyword = Keyword.find_by_keyword(keyword_string)
    self.likes.create(likee_id: likee.id, keyword_id: keyword.id)
  end

  def unlike_a_keyword user_fb_id, keyword_string
    likee = User.find_by_fb_id(user_fb_id)
    keyword = Keyword.find_by_keyword(keyword_string)
    puts "to destory: %d" % self.likes.where("likee_id = ? and keyword_id = ?", likee.id, keyword.id).count
    self.likes.where("likee_id = ? and keyword_id = ?", likee.id, keyword.id).destroy_all
  end

  def keyword_being_liked curr_user, keyword
    return curr_user.likes.where("likee_id = ? and keyword_id = ?", 
           self.id, keyword.id).count == 1
  end
  
  def self.find_or_create fb_id, name
    res = User.find_by_fb_id(fb_id)
    if res == nil
      res = User.create(name: name, fb_id: fb_id)
    end
    return res
  end

  def self.update_options
    # add players that are tester's FB friends to tester's friends list
    fb_friend_ids = @fb_friends.map{|elem| elem["id"]}
    puts self.inspect
    User.each do |user|
      puts "try to add: " + user.name
      if user.signed_up? and fb_friend_ids.include? user.fb_id
        puts "%s is friends of %s on FB" % [user.name, self.name]
        @options << user unless @option.include? user
      end

      # add names that are tester's FB friends and also options of other players to tester's friend list
      user.options.each do |frd|
        next if frd == self
        puts "try to add: " + frd.name
        if fb_friend_ids.include? frd.fb_id
          puts "%s is friends of %s on FB" % [frd.name, self.name]
          @options << user unless @option.include? user
        end
      end

    end
  end

  #
  #========Instance method=============
  #
  
  after_create {
    self.ensure_access_token
    self.update_attribute("logins",[])
    # self.update_attribute("statuses",[])
  }

  def log_in
    self.logins << Time.now
    self.save
  end

  def signed_up?
    self.logins != nil and self.logins.count > 0
  end

  def first_keyword
    if self.profile_keywords[0] == nil
      return nil
    else
      return self.profile_keywords[0].keyword
    end
  end

  def num_comparison_created
    return Quiz.where(author: self.fb_id).count
  end

  def num_keywords_received
    return Rank.where(user: self).sum(:score)
  end

  def num_quizzes_solved
    return self.guesses.select{|guess| guess.answer == guess.quiz.answer}.count
  end

  def all_profile_keywords
    profile_keywords = self.profile_keywords
    res = Array.new
    for keyword in profile_keywords
      times_played = self.ranks.where(keyword: keyword).sum(:score)

      self_id = self.id
      self_index = Rank.about_friends_of(self).where(keyword: keyword).order("score desc").pluck(:user_id).index(self_id)
      ranking = Hash.new
      if self_index != nil
        ranking["self"] = self_index + 1

        lower_index = self_index + 1
        lower_id = Rank.about_friends_of(self).where(keyword: keyword).order("score desc").pluck(:user_id)[lower_index]
        if lower_id != nil
          lower_user = User.find(lower_id)
          ranking["after"] = {name: lower_user.name, fb_id: lower_user.fb_id, rank: (lower_index + 1)}
        end

        if self_index > 0
          higher_index = self_index - 1
          higher_id = Rank.about_friends_of(self).where(keyword: keyword).order("score desc").pluck(:user_id)[higher_index]
          if higher_id != nil
            higher_user = User.find(higher_id)
            ranking["before"] = {name: higher_user.name, fb_id: higher_user.fb_id, rank: (higher_index + 1)}
          end
        end
      end
      has_liked = keyword_being_liked current_user, keyword

      res << [times_played, keyword.keyword, ranking, has_liked]
    end
    return res
  end

  def latest_status
    if self.statuses.order("created_at desc").limit(1)[0] == nil
      return nil
    else
      return self.statuses.order("created_at desc").limit(1)[0]["status"]
    end
  end

  #TODO: let token expire
  def ensure_access_token
    if self.access_token == nil
      access_token = SecureRandom.urlsafe_base64 
      self.update_attribute("access_token", access_token)
    end
  end

  def reset_access_token
    access_token = SecureRandom.urlsafe_base64 
    self.update_attribute("access_token", access_token)
  end

  def increment_badge_number
    self.update_attribute("badge_number", (self.badge_number.to_i + 1))
  end


  def process_fb_friends_ids friends
    fb_ids = friends.collect{|frd| frd['id'].to_i}

    friendships = Array.new
    fb_ids.each do |fb_id|
      friendships << Friendship.new(friend_fb_id: fb_id, user_id: self.id)
    end

    # use activerecord-import gem to do batch insert!
    Friendship.import friendships, :validate => true
    return friendships.count
  end

  # def ensure_fb_friends token
  #   if @fb_friends == nil or @fb_friends.count == 0
  #     Thread.new{
  #       logger.info "Requesting FB friends"
  #       # @graph = Koala::Facebook::API.new(token)
  #       # friends = @graph.get_connections("me", "friends?fields=id")
        
  #       graph = Koala::Facebook::API.new(token)
  #       @fb_friends = graph.get_connections("me", "friends", {"locale"=>"zh_TW"})

  #       logger.info "Finished requesting FB friends"
  #       logger.info "Number of friendships created for User %s: %s" % [@fb_id, @fb_friends.count]
  #     }
  #   end
  # end

 

  # def process_fb_friends_ids friends
  #   @friends = friends
  # end
end
