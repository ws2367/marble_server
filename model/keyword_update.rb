# == Schema Information
#
# Table name: keyword_updates
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  added      :text
#  removed    :text
#  comments   :text
#  uuid       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  popularity :float            default(0.0)
#

class KeywordUpdate < ActiveRecord::Base
  serialize :comments
  serialize :added
  serialize :removed
  belongs_to :user

  after_create {
    self.update_attribute("comments",[])
    self.update_attribute("added",[])   if self.added   == nil
    self.update_attribute("removed",[]) if self.removed == nil
    self.update_attribute("popularity", (self.created_at.to_f - POPULARITY_BASE) * 2)
  }

  self.per_page = 10

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
