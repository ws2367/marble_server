# == Schema Information
#
# Table name: keywords
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  keyword    :string(255)
#

class Keyword < ActiveRecord::Base
  has_many :ranks,   inverse_of: :keyword
  belongs_to :user,  inverse_of: :keywords
end
