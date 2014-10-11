require 'sinatra'
require "sinatra/activerecord"
# require "sinatra/multi_route"
# require 'sinatra/streaming'

require 'json'
require 'csv'
require 'uuidtools'
require 'time'
require 'koala'
# Refer Sinatra+Warden Token Authentication to https://github.com/nmattisson/sinatra-warden-api
require 'warden'
require 'securerandom'

# database
# if ENV['RACK_ENV'] = 'test'
  # set :database, "sqlite3:./test/db/test.sqlite3"
# else
  set :database, "sqlite3:./db/marble.sqlite3"
# end

# models
# run `annotate --model-dir model` to annotate model files
require './model/quiz.rb'
require './model/user.rb'
require './model/guess.rb'
require './model/status.rb'
require './model/rank.rb'
require './model/keyword.rb'

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

  # POST users/set_device_token
  post '/set_device_token' do
    env['warden'].authenticate!(:access_token)
    user = env['warden'].user
    
    device_token = params[:device_token]
    logger.info "device token: %s" % device_token
    
    user.update_attribute("device_token", device_token)
    
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

  get '/status' do
    env['warden'].authenticate!(:access_token)

    puts "GET /status fb_id: %s" % params[:fb_id]

    user = User.find_by_fb_id(params[:fb_id]) if params[:fb_id] != nil
    if user == nil
      logger.info("Cannot find user when updating status")
      status 204
    else
      status 200
      user.statuses.last.to_json
    end
  end

  #
  # ===== updates related request handlers =====
  # 
  
  get '/updates' do
    env['warden'].authenticate!(:access_token)
    user = env['warden'].user
    
    statuses = Status.last(5).map do |s|
      {name: s.user.name, fb_id: s.user.fb_id, uuid:s.uuid,
       status: s.status, created_at: s.created_at}
    end

    status 200
    {"Status" => statuses}.to_json
  end


  #
  # ===== Quiz related request handlers =====
  # 

  post '/quizzes' do
    env['warden'].authenticate!(:access_token)
    
    user = env['warden'].user
    
    q = Quiz.create_quiz_dependencies({
                author_name: params[:author_name], 
                keyword: params[:keyword], 
                option0: params[:option0], 
                option0_name: params[:option0_name],
                option1: params[:option1],  
                option1_name: params[:option1_name],
                answer:  params[:answer],
                uuid:    params[:uuid]}, user)
    
    # puts q.inspect
    status 204 # No Content
  end

  get '/quizzes' do
    env['warden'].authenticate!(:access_token)

    status 200
    {"Quiz" => Quiz.all}.to_json
  end

  post '/comments' do
    env['warden'].authenticate!(:access_token)
    user = env['warden'].user

    puts "On Post(%s), %s made the comment: %s" % [params[:post_uuid], user.name, params[:comment]]

    unless Quiz.insert_comment params[:post_uuid], user, params[:comment]
      unless Status.insert_comment params[:post_uuid], user, params[:comment]
        puts "[ERROR] Cannot find post with uuid %s" % params[:post_uuid].to_s
        halt 400
      end
    end
    
    status 204
  end

  get '/comments' do
    env['warden'].authenticate!(:access_token)

    post = nil
    unless (post = Quiz.find_by_uuid(params[:post_uuid])) != nil
      unless (post = Status.find_by_uuid(params[:post_uuid])) != nil
        puts "[ERROR] Cannot find post with uuid %s" % params[:post_uuid].to_s
        halt 400
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

    user = User.find_by_fb_id(params[:fb_id])
    if user == nil
      puts "[ERROR] Cannot find user with fb_id %s" % params[:fb_id].to_s
      halt 400
    end

    status 200
    user.to_json
  end

  get '/options' do
    env['warden'].authenticate!(:access_token)

    # user = env['warden'].user
    # user.update_options

    res = User.all.map do |opt|
      {name: opt.name, fb_id: opt.fb_id}
    end

    status 200
    res.to_json
  end

  #
  # ===== Guess related request handlers =====
  # 
  
  post '/guesses' do
    env['warden'].authenticate!(:access_token)
    puts "test"
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


  # post '/*' do
  #   path = params[:splat]
  #   puts path.inspect
  #   puts params.inspect
  # end

end