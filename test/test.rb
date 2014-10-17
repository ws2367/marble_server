ENV['RACK_ENV'] = 'test'

require './main.rb'
require 'minitest/autorun'
require 'rack/test'
require 'json'

class MarbleAppTest < Minitest::Test
  include Rack::Test::Methods
  @@token = nil
  
  FB_NAME = "Wen Shaw"
  FB_ID   = "1131095462"
  FB_ACCESS_TOKEN = "CAAIrEsR4cRwBAFvpsHtUVBtXpud0wyca9JgCPpxvKcepWYlbZAawiEHbEnwIBQzwC8U5MR3vp28lXhsfa3RJ04yjMMfKzeAbhNYFMquKkvp1uDOmEDicqAXwSbZB4UEYVwaHcH20FkmtMi8adPjoVj58a3h29OwIHtwKkd2GIH3F1mP4Rkwb0c1OvvRR0pFKJ0wyglZBkXv2ruZAqfCY1XKyhP4L7QyiwtzNiIf0CA2shZCwy9dzb"
  
  def app
    MarbleApp
  end
  
  # run before each test
  def setup
    post '/login', :fb_access_token => FB_ACCESS_TOKEN
    assert last_response.ok?
    # puts "[TEST] -- " + last_response.body
    hash = JSON.parse(last_response.body)
    assert hash.key? "token"
    assert hash.key? "signup"
    assert hash["signup"] == "false" or hash["signup"] == "true"
    assert hash["token"].class == String and hash["token"].length > 0
    @@token = hash["token"]
  end

  def auth_params
    {:auth_token => @@token}
  end

  def test_it_logs_out
    puts "[TEST] -- " + "token: " + @@token.to_s
    delete '/logout', auth_params
    assert last_response.status == 204
  end

  def test_it_post_and_get_quizzes
    uuid = UUIDTools::UUID.random_create.to_s
    params = {:auth_token => @@token, 
              :keyword => "keyword2", 
              :option0 => "204958204",
              :option0_name => "name 0",
              :option1 => "220591204",
              :option1_name => "name 1",
              :answer  => "220591204",
              :uuid    => uuid
             }
    post '/quizzes', params
    assert last_response.status == 204

    get '/quizzes', auth_params
    assert last_response.ok?
    hash = JSON.parse(last_response.body)
    assert hash.key? "Quiz"
    matches = hash["Quiz"].select{|quiz| quiz["uuid"] == uuid}
    assert matches.count == 1 # find one quiz of which uuid matches the uuid sent
  end

  def test_it_get_users_and_options
    get '/options', auth_params
    assert last_response.ok?
    first_resp = JSON.parse(last_response.body)
    assert first_resp[0].key? "name"
    assert first_resp[0].key? "fb_id"

    get '/user', {:auth_token => @@token, :fb_id => first_resp[0]["fb_id"]}
    assert last_response.ok?
    second_resp = JSON.parse(last_response.body)
    puts '[TEST] -- ' + second_resp.inspect
    assert second_resp["name"] == first_resp[0]["name"]
  end

  def test_it_set_device_token
    post '/set_device_token', {:auth_token   => @@token, 
                               :device_token => "asdlkajqweoijdas"}
    assert last_response.status == 204
  end

  def test_it_post_and_get_comment
    get '/quizzes', auth_params
    assert last_response.ok?
    hash = JSON.parse(last_response.body)
    uuid = hash["Quiz"][0]["uuid"]

    post '/comments', {:auth_token => @@token,
                       :post_uuid  => uuid,
                       :comment    => "test comment"}
    assert last_response.status == 204

    get '/comments', {:auth_token => @@token,
                      :post_uuid  => uuid}
    assert last_response.ok?
    hash = JSON.parse(last_response.body)
    matches = hash["comments"].select{|comment| comment["comment"] == "test comment"}
    assert matches.count > 0
  end

  def test_it_post_and_get_status_and_comment
    post '/status', {:auth_token => @@token, 
                     :status     => "test status"}
    assert last_response.status == 204

    get '/user', {:auth_token => @@token, :fb_id => FB_ID}
    assert last_response.ok?
    hash = JSON.parse(last_response.body)
    assert_equal hash["latest_status"]["status"], "status", "Failed to post/get status"

    post '/comments', {:auth_token => @@token,
                       :post_uuid  => hash['uuid'],
                       :comment    => "test status comment"}
    assert_equal last_response.status, 204

    get '/comments', {:auth_token => @@token,
                      :post_uuid  => hash['uuid']}
    assert last_response.ok?
    hash = JSON.parse(last_response.body)
    matches = hash["comments"].select{|comment| comment["comment"] == "test status comment"}
    assert_equal matches.first["name"], FB_NAME, "Name in the comment does not match."

    # puts "[TEST] -- " + matches.inspect
    assert matches.count > 0
  end

  def test_it_get_updates
    get '/updates', auth_params
    assert last_response.ok?
    hash = JSON.parse(last_response.body)
    assert hash.key? "Status_Update"
    assert hash.key? "Keyword_Update"

    uuid = hash["Keyword_Update"][0]["uuid"]
    post '/comments', {:auth_token => @@token,
                       :post_uuid  => uuid,
                       :comment    => "test keyword comment"}

    # puts "[TEST] --" + hash.inspect
  end

  def test_it_get_keywords
    get '/keywords', auth_params
    assert last_response.ok?
    hash = JSON.parse(last_response.body)
    puts "[TEST] --" + hash.inspect
  end


  def test_it_get_notifications
    get '/notifications', auth_params
    assert last_response.ok?
    hash = JSON.parse(last_response.body)
    assert hash.key? "comment"
    assert hash.key? "quiz"
    assert hash.key? "keyword_updates"
    
    puts "[TEST] -- Notification: " + hash.inspect
  end

  def after_tests

  end

  # describe Person do

  # before do
  #   @person = Person.new
  # end

  # describe "name is empty" do
  #   it "is not valid" do
  #     @person.valid?.wont_equal true
  #   end
  # end

  # describe "name is not empty" do
  #   before do
  #     @person.first_name = "Yukihiro"
  #     @person.last_name = "Matsumoto"
  #   end

  #   it "is valid" do
  #     @person.valid?.must_equal true
  #   end

  #   it "has a full name" do
  #     @person.full_name.must_equal "Yukihiro Matsumoto"
  #   end
  # end

# end
end