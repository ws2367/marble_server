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
  }

  def self.insert_comment post_uuid, user, comment
    keyword_update = KeywordUpdate.find_by_uuid(post_uuid)
    if keyword_update != nil
      keyword_update.comments << {fb_id: user.fb_id, name:user.name,
                                  comment: comment, time: Time.now}
      keyword_update.save
      return true
    else
      return false
    end
  end
end
