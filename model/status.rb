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
#  popularity :float            default(0.0)
#

class Status < ActiveRecord::Base
  serialize :comments
  belongs_to :user

  after_create {
    self.update_attribute("comments",[])
    self.update_attribute("popularity", (self.created_at.to_f - POPULARITY_BASE) * 2)
  }

  self.per_page = 10

  def self.insert_comment post_uuid, user, comment
    status = Status.find_by_uuid(post_uuid)
    if status != nil
      status.comments << {fb_id: user.fb_id, name:user.name,
                          comment: comment, time: Time.now}
      subtrahend = (status.comments.count > 1 ? status.comments.last(2)[0][:time].to_f :
                                                status.created_at.to_f)
      status.popularity = status.popularity.to_f - subtrahend + status.comments.last[:time].to_f + 300.0
      status.save
      return status
    else
      return nil
    end
  end

  def self.about_friends_of user
    Status.joins(:user).
           joins('INNER JOIN friendships ON friendships.friend_fb_id = users.fb_id AND
                                            friendships.user_id = %d' % user.id).distinct
  end

  def self.about_user(fb_id)
    user = User.find_by_fb_id(fb_id)
    return where(user: user)
  end

  def self.map_to_respond statuses
    statuses.map do |s|
      {name: s.user.name, fb_id: s.user.fb_id, uuid:s.uuid,
       status: s.status, created_at: s.created_at, popularity: s.popularity}
    end
  end

  scope :popular,
    order("popularity desc, updated_at desc, id desc")

  def self.query_popular_posts(user_id, start_over, last_id)
    query_result = Post.active.popular
    return fetch_segment(query_result, start_over, last_of_previous_post_ids)
  end


end
