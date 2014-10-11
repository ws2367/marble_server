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

  def self.find_or_create keyword, user
    res = user.ranks.find_by_keyword_id(keyword.id)
    if res == nil
      res = user.ranks.create(keyword_id: keyword.id)
    end
    return res
  end

  def increment_score
    self.update_attribute("score", self.score.to_i + 1)
  end

end
