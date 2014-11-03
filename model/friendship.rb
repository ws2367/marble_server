# == Schema Information
#
# Table name: friendships
#
#  id           :integer          not null, primary key
#  friend_fb_id :integer
#  user_id      :integer
#  created_at   :datetime
#  updated_at   :datetime
#

class Friendship < ActiveRecord::Base  
  belongs_to :friends, class_name: "User", foreign_key: "friend_fb_id", primary_key: :fb_id, inverse_of: :friendships
  belongs_to :user

  validates :user_id, :friend_fb_id, presence: true

  validate :unique_friendship, on: :create

  def unique_friendship
    if Friendship.exists?(user_id: user_id, friend_fb_id: friend_fb_id)
      errors.add(:friendship, "has existed.")
    end
  end
end
