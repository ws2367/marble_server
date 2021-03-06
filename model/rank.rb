# == Schema Information
#
# Table name: ranks
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  keyword_id :integer
#  score      :integer
#  created_at :datetime
#  updated_at :datetime
#

class Rank < ActiveRecord::Base

  NUM_PROFILE_KEYWORD = 10

  belongs_to :keyword, inverse_of: :ranks
  belongs_to :user,    inverse_of: :ranks

  after_create {
    self.update_attribute("score", 0)
  }

  def self.find_or_create keyword, user
    res = user.ranks.find_by_keyword_id(keyword.id)
    if res == nil
      res = user.ranks.create(keyword_id: keyword.id)
    end
    return res
  end

  def self.about_friends_of user
    Rank.joins(:user).
         joins('INNER JOIN friendships ON friendships.friend_fb_id = users.fb_id AND '\
                                         'friendships.user_id = %d' % user.id).distinct
  end

  def increment_score
    self.update_attribute("score", self.score.to_i + 1)
    timers = Timers::Group.new
    timers.after(TIME_TO_CHECK_KEYWORD_UPDATES) { # 10 mins later
      puts "[DEBUG] 10-min timer fired and will check keyword updates"
      ActiveRecord::Base.connection_pool.with_connection do
        check_if_keyword_updates
      end
    }

    Thread.new{
      puts "[DEBUG] scheduled a 10-min timer to check keyword updates"
      timers.wait
    }
  end
  
  
  def check_if_keyword_updates
    old_keyword = self.user.profile_keywords
    new_keyword = self.user.ranks.order("score desc").limit(NUM_PROFILE_KEYWORD).map{|r| r.keyword}

    # if keyword update needs to be issued
    unless (old_keyword - new_keyword).empty? and (new_keyword - old_keyword).empty?

      to_remove = old_keyword - new_keyword
      to_add    = new_keyword - old_keyword

      while to_add.count > 0
        three_keywords = to_add.slice!(0, 3)
        keyword_update = self.user.keyword_updates.new(removed: to_remove.map{|k| k.id}, 
                                                          uuid: UUIDTools::UUID.random_create.to_s)

        keyword_update.keyword1 = three_keywords[0].keyword if three_keywords[0]
        keyword_update.keyword2 = three_keywords[1].keyword if three_keywords[1]
        keyword_update.keyword3 = three_keywords[2].keyword if three_keywords[2]
        keyword_update.save
        
        unless to_remove.empty?
          self.user.profile_keywords.delete(to_remove) 
          to_remove = []
        end
        self.user.profile_keywords << three_keywords
        self.user.save
      end
    end

  end
end
