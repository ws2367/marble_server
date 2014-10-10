# == Schema Information
#
# Table name: statuses
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  status     :string(255)
#  comments   :text
#  created_at :datetime
#  updated_at :datetime
#  uuid       :string(255)
#

class Status < ActiveRecord::Base
  serialize :comments
  belongs_to :user

  after_create {
    self.update_attribute("comments",[])
  }

  def self.insert_comment post_uuid, fb_id, comment
    status = Status.find_by_uuid(post_uuid)
    if status != nil
      status.comments << {fb_id: fb_id, comment: comment, time: Time.now}
      status.save
      return true
    else
      return false
    end
  end
end
