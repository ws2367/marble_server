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
#

class User < ActiveRecord::Base
  serialize :logins
  has_many :statuses, inverse_of: :user
  has_many :guesses,  inverse_of: :user
  has_many :keywords, inverse_of: :user
  has_many :ranks,    inverse_of: :user
  has_many :keyword_updates, inverse_of: :user
  has_and_belongs_to_many :profile_keywords, class_name: "Keyword"
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
      return ""
    else
      self.profile_keywords[0].keyword
    end
  end

  def all_profile_keywords
     self.profile_keywords.pluck(:keyword)
  end

  def latest_status
    self.statuses.order("created_at desc").limit(1)[0]
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
