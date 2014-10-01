require 'sinatra'
# require "sinatra/activerecord"
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
# set :database, "sqlite3:///./db/glue.sqlite3"

# models
require './librarian.rb'
require './model/glue.rb'
require './model/user.rb'
# require './player_mgr.rb'


module GL
 
class GlueApp < Sinatra::Application
  @@users = []
  # @@librarian = Librarian.new
  # enable :sessions

  # set the content-type of all responses application/json
  before do
    content_type 'application/json'
  end

  def self.read_credentials
    path = "config/app_credentials"
    var_names = Array.new
    begin
      File.readlines(path).each do |line|
        values = line.split("=")
        var_name = values[0].chomp.strip
        ENV[var_name] = values[1].chomp.strip
        var_names << var_name
      end
      if var_names.count > 1
        puts "[DEBUG] ENV variables %s are set." % var_names.join(' ,')
      elsif var_names.count > 0
        puts "[DEBUG] ENV variable %s is set." % var_names.join(' ,')
      else
        puts "[DEBUG] No ENV variable is set."
      end
    rescue
      puts
      puts "[ERROR] CANNOT find the credential file at path %s" % path
      puts
    end
  end

  configure do
    read_credentials
  end

  # Configure Warden
  use Warden::Manager do |config|
    config.scope_defaults :default,
    # Set your authorization strategy
    strategies: [:access_token],
    # Route to redirect to when warden.authenticate! returns a false answer.
    action: '/unauthenticated'
    config.failure_app = self
  end

  Warden::Manager.before_failure do |env,opts|
    env['REQUEST_METHOD'] = 'POST'
  end

  # Implement your Warden stratagey to validate and authorize the access_token.
  Warden::Strategies.add(:access_token) do
    def valid?
        # Validate that the access token is properly formatted.
        # Currently only checks that it's actually a string.
        # puts "test " + params[:auth_token].to_s
        request.env["HTTP_ACCESS_TOKEN"].is_a?(String) or 
        params["auth_token"].is_a?(String)
    end

    # curl -i -H "access_token: youhavenoprivacyandnosecrets" http://localhost:4567/protected
    def authenticate!
        # Authorize request if HTTP_ACCESS_TOKEN matches 'youhavenoprivacyandnosecrets'
        # Your actual access token should be generated using one of the several great libraries
        # for this purpose and stored in a database, this is just to show how Warden should be
        # set up.
        token = (request.env["HTTP_ACCESS_TOKEN"] == nil) ? 
                 params["auth_token"] : request.env["HTTP_ACCESS_TOKEN"]
        user = User.find_by_access_token(token)
        user == nil ? fail!("Could not log in") : success!(user)
    end
  end

  #
  #========== Routes ==============
  #
  post '/login' do
    puts "start to login"
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
    puts "yo0"
    puts fb_access_token.to_s
    # check if the access token is valid and issued from our app 
    debug_info = app_graph.debug_token(fb_access_token)
    puts "yo0.25"
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
    puts "yo0.5"
    @graph = Koala::Facebook::API.new(fb_access_token)
    puts "yo1"
    profile = @graph.get_object("me")

    fb_user_id = profile["id"].to_i
    name       = profile["name"]
    
    logger.info "User (id: %s, name: %s) logged in." % [fb_user_id.to_s, name]

    @user = User.find_by_fb_id(fb_user_id)
    
    resp = Hash.new
    if @user.nil?
      logger.info("User #{fb_user_id} failed signin. The user was then created.")
      @user = User.new(name, fb_user_id)
      
      resp['signup'] = 'true'
    else
      resp['signup'] = 'false'
    end

    @user.log_in
    @user.ensure_fb_friends fb_access_token
    @user.ensure_access_token
    resp["token"] = @user.access_token

    content_type :json
    status 200
    resp.to_json
  end

  # This is the route that unauthorized requests gets redirected to.
  post '/unauthenticated' do
    content_type :json
    { message: "Sorry, this request can not be authenticated. Try again." }.to_json
  end


  get '/protected' do
    env['warden'].authenticate!(:access_token)
  
    "Welcome!" + env['warden'].user.inspect
  end

  post '/quizzes' do
    env['warden'].authenticate!(:access_token)
    
    user = env['warden'].user
    puts params.inspect
    keyword = params[:keyword]
    option0 = params[:option0]
    option1 = params[:option1]
    answer  = params[:answer]

    # glue = {author:xxx, keyword:xx, option0:xx, option1:xx, answer:xx, time:xx}
    glue  = Glue.new("author" => user.fb_id, "keyword"=>keyword, "option0"=>option0, 
                     "option1"=> option1,    "answer"=>answer)

    puts Glue.list
    status 204 # No Content
  end


  get '/initialOptions' do
    env['warden'].authenticate!(:access_token)

    user = env['warden'].user
    user.update_options

    puts user.options.inspect

    status 200
    user.options.to_json
  end

  post '/*' do
    path = params[:splat]
    puts path.inspect
    puts params.inspect
  end

  # # start the server if ruby file executed directly
  run! if app_file == $0
end
end