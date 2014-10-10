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
end
