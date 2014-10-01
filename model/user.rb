class User
  attr_accessor :name, :fb_id, :access_token, :friends, :fb_friends, :options
  @@users = []

  #
  #=========Class method============
  #
  def self.find_by_fb_id fb_id
    selected = @@users.select{|user| user.fb_id == fb_id}
    if selected.count == 1
      return selected[0]
    else
      return nil
    end
  end

  def self.find_by_access_token token
    selected = @@users.select{|user| user.access_token == token}
    if selected.count == 1
      return selected[0]
    else
      return nil
    end
  end

  #
  #========Instance method=============
  #
  def initialize name, fb_id
    @name = name
    @fb_id = fb_id
    @@users << self
  end

  def log_in
    @login = Array.new if @login == nil
    @login << Time.now
  end

  def signed_up?
    @login != nil and @login.count > 0
  end

  def update_options
    # add players that are tester's FB friends to tester's friends list
    fb_friend_ids = @fb_friends.map{|elem| elem["id"]}
    (@@users - [self]).each do |user|
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

  
  def ensure_fb_friends token
    if @fb_friends == nil or @fb_friends.count == 0
      Thread.new{
        logger.info "Requesting FB friends"
        # @graph = Koala::Facebook::API.new(token)
        # friends = @graph.get_connections("me", "friends?fields=id")
        
        graph = Koala::Facebook::API.new(token)
        @fb_friends = graph.get_connections("me", "friends", {"locale"=>"zh_TW"})

        logger.info "Finished requesting FB friends"
        logger.info "Number of friendships created for User %s: %s" % [@fb_id, @fb_friends.count]
      }
    end
  end

  #TODO: let token expire
  def ensure_access_token
    @access_token = SecureRandom.urlsafe_base64 if @access_token == nil
  end

  def process_fb_friends_ids friends
    @friends = friends
  end
end