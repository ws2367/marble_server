# == Schema Information
#
# Table name: keyword_updates
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  removed    :text
#  comments   :text
#  uuid       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  popularity :float            default(0.0)
#  keyword1   :string(255)
#  keyword2   :string(255)
#  keyword3   :string(255)
#

class KeywordUpdate < ActiveRecord::Base
  serialize :comments
  serialize :removed
  belongs_to :user

  after_create {
    self.update_attribute("comments",[])
    self.update_attribute("removed",[]) if self.removed == nil
    self.update_attribute("popularity", (self.created_at.to_f - POPULARITY_BASE) * 2)
  }

  self.per_page = 10

  def self.about_user(fb_id)
    user = User.find_by_fb_id(fb_id)
    return where(user: user)
  end

  def self.about_friends_of user
    KeywordUpdate.joins(:user).
           joins('INNER JOIN friendships ON friendships.friend_fb_id = users.fb_id AND '\
                                           'friendships.user_id = %d' % user.id).distinct
  end

  def self.about_keyword(keyword)
    return where("keyword1 = ? OR keyword2 = ? OR keyword3 = ?", keyword, keyword, keyword)

  end

  def self.map_to_respond keyword_updates
    keyword_updates.map do |k|
      {name: k.user.name, fb_id: k.user.fb_id, uuid: k.uuid, 
       created_at: k.created_at, popularity: k.popularity }.
       merge(KeywordUpdate.generate_keyword_response(k))
    end
  end

  def self.generate_keyword_response k
    res = Hash.new
    res[:keyword1] = k.keyword1 if k.keyword1
    res[:keyword2] = k.keyword2 if k.keyword2
    res[:keyword3] = k.keyword3 if k.keyword3
    return res
  end

  def self.insert_comment post_uuid, user, comment
    keyword_update = KeywordUpdate.find_by_uuid(post_uuid)
    if keyword_update != nil
      keyword_update.comments << {fb_id: user.fb_id, name:user.name,
                                  comment: comment, time: Time.now}

      subtrahend = (keyword_update.comments.count > 1 ? keyword_update.comments.last(2)[0][:time].to_f :
                                                        keyword_update.created_at.to_f)

      keyword_update.popularity = keyword_update.popularity.to_f - subtrahend + 
                                  keyword_update.comments.last[:time].to_f + 300.0
      keyword_update.save
      return keyword_update
    else
      return nil
    end
  end
end
