# == Schema Information
#
# Table name: likes
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  likee_id   :integer
#  keyword_id :integer
#  created_at :datetime
#  updated_at :datetime
#

class Like < ActiveRecord::Base
  belongs_to :user,    inverse_of: :likes
  belongs_to :keyword, inverse_of: :likes
end
