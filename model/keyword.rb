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
  has_many :likes,   inverse_of: :keyword
  has_and_belongs_to_many :receivers, class_name: "User"

  def self.find_or_create keyword_, user
    res = Keyword.find_by_keyword(keyword_)
    if res == nil
      res = user.keywords.create(keyword: keyword_)
    end
    return res
  end

  
  
end
  