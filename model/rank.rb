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
  belongs_to :keyword, inverse_of: :ranks
  belongs_to :user,    inverse_of: :ranks

  after_create {
    self.update_attribute("score", 0)
  }
end
