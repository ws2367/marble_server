class Player
  
  attr_accessor :name, :fb_id, :friends

  def initialize name, fb_id
    @name = name
    @fb_id = fb_id
  end

  def ensure_fb_friends token
    if @fb_friends == nil or  @fb_friends.count == 0
      Thread.new{
        graph = Koala::Facebook::API.new(token)
        @fb_friends = graph.get_connections("me", "friends", {"locale"=>"zh_TW"})
      }
    end
  end
end