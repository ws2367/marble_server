require 'sinatra'
require "sinatra/activerecord"
require "activerecord-import"
# require "sinatra/multi_route"
# require 'sinatra/streaming'

require 'json'
require 'csv'
require 'uuidtools'
require 'time'
require 'koala'
# Refer Sinatra+Warden Token Authentication to https://github.com/nmattisson/sinatra-warden-api
require 'warden'
require 'houston'
require 'securerandom'
require 'will_paginate'
require 'will_paginate/active_record'

# database
# if ENV['RACK_ENV'] = 'test'
  # set :database, "sqlite3:./test/db/test.sqlite3"
# else
  set :database, "sqlite3:./db/marble.sqlite3"
# end

# models
# run `annotate --model-dir model` to annotate model files
POPULARITY_BASE = 1396310400.0
NUM_KEYWORD_RANKING = 3

require './model/quiz.rb'
require './model/friendship.rb'
require './model/user.rb'
require './model/guess.rb'
require './model/status.rb'
require './model/rank.rb'
require './model/keyword.rb'
require './model/keyword_update.rb'

Dir.glob('./config/*.rb').each do |file|
  require file
end

class MarbleApp < Sinatra::Application
  register Sinatra::ActiveRecordExtension
  # enable :sessions

  # set the content-type of all responses application/json
  before do
    content_type 'application/json'
  end

  configure do 
    @@apn = Houston::Client.development
    @@apn.certificate = File.read("config/apn_development_marble.pem")
  end
  
  def send_push_notification user, alert, badge, custom_data
    if user.device_token != nil
      notification = Houston::Notification.new(device: user.device_token)
      notification.alert = alert
      notification.badge = badge
      if custom_data != nil
        notification.content_available = true
        notification.custom_data = custom_data
      end

      @@apn.push(notification)  
      puts "Notification is sent to user #{user.name}"
    end
  end
  #
  #========== Routes ==============
  #
  post '/login' do

    fb_access_token = params[:fb_access_token]

    app_id = ENV['FB_APP_ID']
    app_secret = ENV['FB_APP_SECRET']

    if fb_access_token.nil?
      puts "The request contains no token."
      render :status=>400,
             :json=>{:message=>"The request must contain the FB access token."}
      return
    end

    oauth = Koala::Facebook::OAuth.new(app_id, app_secret)
    app_access_token = oauth.get_app_access_token
    app_graph = Koala::Facebook::API.new(app_access_token)

    # check if the access token is valid and issued from our app 
    debug_info = app_graph.debug_token(fb_access_token)

    if debug_info["data"]["is_valid"] == false 
      puts "The FB access token is invalid"
      halt 400,  {'Content-Type' => 'application/json'}, 
           {:message=>"The FB access token is invalid"}.to_json
      
      return
    elsif debug_info["data"]["app_id"] != app_id.to_s
      puts "The FB access token is issued from other apps"
      halt 400,  {'Content-Type' => 'application/json'}, 
           {:message=>"The FB access token is issued from other apps"}.to_json
            
      return
    end
    @graph = Koala::Facebook::API.new(fb_access_token)
    profile = @graph.get_object("me")

    fb_user_id = profile["id"].to_i
    name       = profile["name"]
    
    logger.info "User (id: %s, name: %s) logged in." % [fb_user_id.to_s, name]

    @user = User.find_by_fb_id(fb_user_id)
    
    resp = Hash.new
    if @user.nil?
      logger.info("User #{fb_user_id} failed signin. The user was then created.")
      @user = User.create(name: name, fb_id: fb_user_id)
      
      resp['signup'] = 'true'
      #TODO: move the work to background
      Thread.new {
        logger.info "Requesting FB friends"
        friends = @graph.get_connections("me", "friends?fields=id")
        logger.info "Finished requesting FB friends"
        count = @user.process_fb_friends_ids friends
        logger.info "Number of friendships created for User %s: %s" % [@user.id, count]
      }
    else
      resp['signup'] = 'false'
    end

    @user.log_in
    # @user.ensure_fb_friends fb_access_token
    @user.ensure_access_token
    resp["token"] = @user.access_token

    puts "token: " + @user.access_token

    content_type :json
    status 200
    resp.to_json
  end

  # This is the route that unauthorized requests gets redirected to.
  post '/unauthenticated' do
    content_type :json
    { message: "Sorry, this request can not be authenticated. Try again." }.to_json
  end

  delete '/logout' do #mapped to DELETE users/sign_out 
    env['warden'].authenticate!(:access_token)
    @user = env['warden'].user
    puts params.inspect
    if @user.nil?
      logger.info("Token not found.")
      halt 404,  {'Content-Type' => 'application/json'}, 
           {:message=>"Invalid token."}.to_json
    else
      @user.update_attribute("device_token", nil)
      @user.reset_access_token
    end

    status 204
  end

 
  #
  # ===== updates related request handlers =====
  # 
  
  # get '/updates' do
  #   env['warden'].authenticate!(:access_token)
  #   user = env['warden'].user
  #   puts "[DEBUG] -- page: " + params[:page]
  #   statuses = 
  #     Status.order('created_at DESC').page(params[:page]).map do |s|
  #     {name: s.user.name, fb_id: s.user.fb_id, uuid:s.uuid,
  #      status: s.status, created_at: s.created_at, popularity: s.popularity}
  #   end

  #   keyword_updates = 
  #     KeywordUpdate.order('created_at DESC').page(params[:page]).map do |k|
  #     {name: k.user.name, fb_id: k.user.fb_id, uuid: k.uuid, 
  #      keywords: k.added.map{|a| Keyword.find_by_id(a).keyword}, 
  #      created_at: k.created_at, popularity: k.popularity }
  #   end

  #   status 200
  #   {"Status_Update" => statuses, "Keyword_Update" => keyword_updates}.to_json
  # end


  #
  # ===== Quiz related request handlers =====
  # 

  post '/quizzes' do
    env['warden'].authenticate!(:access_token)
    
    user = env['warden'].user
    
    #TODO: let Quiz model be associated with User as 
    #      in author, option0 and option1
    opt0, opt1, quiz = Quiz.create_quiz_dependencies({
                        author_name: params[:author_name], 
                        keyword: params[:keyword], 
                        option0: params[:option0], 
                        option0_name: params[:option0_name],
                        option1: params[:option1],  
                        option1_name: params[:option1_name],
                        answer:  params[:answer],
                        uuid:    params[:uuid]}, user)
    
    opt0.increment_badge_number
    opt1.increment_badge_number

    alert = "#{params[:author_name]} compared you"
    send_push_notification opt0, alert, opt0.badge_number, {post_uuid: params[:uuid]}
    send_push_notification opt1, alert, opt1.badge_number, {post_uuid: params[:uuid]}

    status 200
    quiz.to_json(:only => [:uuid, :popularity, :created_at])
  end

  get '/posts' do
    env['warden'].authenticate!(:access_token)
    user = env['warden'].user

    puts "[DEBUG] -- page: " + params[:page].to_s

    fb_id = params[:fb_id]
    puts "[DEBUG] -- fb_id: " + fb_id.to_s

    keyword = params[:keyword]
    puts "[DEBUG] -- keyword: " + keyword.to_s

    post_uuid = params[:post_uuid]
    puts "[DEBUG] -- post_uuid: " + post_uuid.to_s

    quizzes = statuses = keyword_updates = nil
    if fb_id != nil
      quizzes = Quiz.map_to_respond(Quiz.about_user(fb_id).order('created_at DESC').page(params[:page]), user)      
      statuses = Status.map_to_respond(Status.about_user(fb_id).order('created_at DESC').page(params[:page]))
      keyword_updates = KeywordUpdate.map_to_respond(KeywordUpdate.about_user(fb_id).order('created_at DESC').page(params[:page]))
    
    elsif keyword != nil
      quizzes = Quiz.map_to_respond(Quiz.about_friends_of(user).about_keyword(keyword).order('created_at DESC').page(params[:page]), user)
      statuses = []
      keyword_updates = KeywordUpdate.map_to_respond(KeywordUpdate.about_friends_of(user).about_keyword(keyword).order('created_at DESC').page(params[:page]))
    
    elsif post_uuid != nil
      quizzes  = Quiz.map_to_respond(Quiz.find_by_uuid(post_uuid))
      statuses = Status.map_to_respond(Status.find_by_uuid(post_uuid)) if quizzes == nil
      keyword_updates = KeywordUpdate.map_to_respond(KeywordUpdate.find_by_uuid(post_uuid)) if statuses == nil
    
    else
      quizzes = Quiz.map_to_respond(Quiz.about_friends_of(user).order('created_at DESC').page(params[:page]), user)
      statuses = Status.map_to_respond(Status.about_friends_of(user).order('created_at DESC').page(params[:page]))
      keyword_updates = KeywordUpdate.map_to_respond(KeywordUpdate.about_friends_of(user).order('created_at DESC').page(params[:page]))
    end
    
    status 200
    {"Quiz" => quizzes, "Status_Update" => statuses, 
     "Keyword_Update" => keyword_updates}.to_json
    # {"Quiz" => Quiz.all}.to_json(:except  => [ :id, :updated_at, :comments],
    #                              :methods => :answered_before(user))
  end

  post '/comments' do
    env['warden'].authenticate!(:access_token)
    user = env['warden'].user

    puts "On Post(%s), %s made the comment: %s" % [params[:post_uuid], user.name, params[:comment]]
    post = nil
    unless (post = Quiz.insert_comment params[:post_uuid], user, params[:comment])
      unless (post = Status.insert_comment params[:post_uuid], user, params[:comment])
        unless (post = KeywordUpdate.insert_comment params[:post_uuid], user, params[:comment])
          puts "[ERROR] Cannot find post with uuid %s" % params[:post_uuid].to_s
          halt 400
        end
      end
    end

    receiver = post.user
    if receiver.id != user.id
      puts "Going to send notificationt for comments on %s" % post.user.name
      badge_number = receiver ? receiver.badge_number : 1
      alert = "#{user.name} commented on your post"
      send_push_notification receiver, alert, badge_number, {post_uuid: params[:post_uuid]}
    end
    status 204
  end

  get '/comments' do
    env['warden'].authenticate!(:access_token)

    post = nil
    unless (post = Quiz.find_by_uuid(params[:post_uuid])) != nil
      unless (post = Status.find_by_uuid(params[:post_uuid])) != nil
        unless (post = KeywordUpdate.find_by_uuid(params[:post_uuid])) != nil
          puts "[ERROR] In GET /comment, cannot find post with uuid %s" % params[:post_uuid].to_s
          halt 400
        end
      end
    end

    status 200
    # so we can disguise it as a post
    {uuid: post.uuid, comments: post.comments}.to_json
  end

  #
  # ===== User related request handlers =====
  # 
  
  get '/user' do
    env['warden'].authenticate!(:access_token)

    user = User.find_by_fb_id(params[:fb_id]) if params[:fb_id] != nil
    if user == nil
      puts "[ERROR] Cannot find user with fb_id %s" % params[:fb_id].to_s
      halt 400
    end

    status 200
    user.to_json(:only    => [:name, :fb_id], 
                 :methods => [:num_comparison_created, :num_keywords_received, 
                              :num_quizzes_solved, :latest_status, 
                              :all_profile_keywords])
  end

  get '/options' do
    env['warden'].authenticate!(:access_token)

    status 200
    User.all.to_json(:only => [:fb_id, :name], :methods => :first_keyword)
  end

  # POST users/set_device_token
  post '/set_device_token' do
    env['warden'].authenticate!(:access_token)
    user = env['warden'].user
    
    device_token = params[:device_token]
    logger.info "device token: %s" % device_token
    
    user.update_attribute("device_token", device_token)
    
    status 204
  end
  
  post '/set_badge_number' do
    env['warden'].authenticate!(:access_token)
    user = env['warden'].user

    badge_number = params["badge_number"]
    puts "[DEBUG] -- received badge number " + badge_number.to_s
    user.update_attribute("badge_number", badge_number)

    status 204
  end

  post '/status' do
    env['warden'].authenticate!(:access_token)
    user = env['warden'].user

    user.statuses.create(status: params[:status], 
                         uuid: UUIDTools::UUID.random_create.to_s)
    user.save

    status 204
  end

  #
  # ===== Keyword related request handlers =====
  # 

  get '/keywords' do
    env['warden'].authenticate!(:access_token)

    status 200
    Keyword.all.pluck(:keyword).to_json
  end


  get '/keyword' do 
    env['warden'].authenticate!(:access_token)
    user = env['warden'].user
    keyword = Keyword.find_by_keyword(params[:keyword])
    unless keyword
      puts "Cannot find keyword %s in GET /keyword" % params[:keyword]
      halt 400
    end

    users = Rank.about_friends_of(user).where(keyword: keyword).order("score desc").
            limit(NUM_KEYWORD_RANKING).map.with_index{|r, i| [i, {name: r.user.name,
                                                                  fb_id: r.user.fb_id}]}

    times_played = Rank.where(keyword: keyword).sum(:score)

    creator = keyword.user

    status 200
    {ranking: users, times: times_played, 
     creator: creator}.to_json
  end
  #
  # ===== Guess related request handlers =====
  # 
  
  post '/guesses' do
    env['warden'].authenticate!(:access_token)

    user = env['warden'].user
    quiz = Quiz.find_by_uuid(params[:quiz_uuid])
    if quiz == nil
      puts "[ERROR] Cannot find quiz with uuid %s" % params[:quiz_uuid].to_s
      halt 400
    end

    g = user.guesses.create(quiz_id: quiz.id,
                            answer:  params[:answer])


    # Guess.create(user_id)
    status 204
  end

  get '/notifications' do
    env['warden'].authenticate!(:access_token)
    user = env['warden'].user

    ## comments
    quizzes_comments = Quiz.where("option1 = ? or option0 = ? or author = ?",
                       user.fb_id, user.fb_id, user.fb_id).pluck(:uuid, :comments).
                       map{|t| t[1].map{|s| s["post_uuid"] = t[0]; s["type"] = "quiz"}; 
                       t[1]}.flatten(1).sort{|a,b| a[:time] <=> b[:time]}.last(10)

    keyword_comments = user.keyword_updates.pluck(:uuid, :comments).
                       map{|t| t[1].map{|s| s["post_uuid"] = t[0]; s["type"] = "keyword"};
                       t[1]}.flatten(1).sort{|a,b| a[:time] <=> b[:time]}.last(10)

    status_comments  = user.statuses.pluck(:uuid, :comments).
                       map{|t| t[1].map{|s| s["post_uuid"] = t[0]; s["type"] = "status"};
                       t[1]}.flatten(1).sort{|a,b| a[:time] <=> b[:time]}.last(10)

    ## keyword updates
    keyword_updates = user.keyword_updates.order("created_at desc").limit(10)

    ## quizzes
    quizzes = Quiz.where("option1 = ? or option0 = ?", 
              user.fb_id, user.fb_id).limit(10).map{|q|
               p = q.attributes
               p.delete("updated_at")
               p.delete("keyword_id")
               p.delete("id")
               p["answered_before"] = q.answered_before(user)
               p
              }

    resp = {
      comment: 
        quizzes_comments + 
        keyword_comments +
        status_comments,
      quiz: quizzes,
      keyword_update: keyword_updates
    }
  
    status 200
    resp.to_json
  end

  # post '/*' do
  #   path = params[:splat]
  #   puts path.inspect
  #   puts params.inspect
  # end

end