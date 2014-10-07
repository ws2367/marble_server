ENV['RACK_ENV'] = 'test'

require './main.rb'
require 'minitest/autorun'
require 'rack/test'
require 'json'

class MarbleAppTest < Minitest::Test
  include Rack::Test::Methods
  @@token = nil
  def app
    MarbleApp
  end
  
  # run before each test
  def setup
    post '/login', :fb_access_token => "CAAIrEsR4cRwBAFvpsHtUVBtXpud0wyca9JgCPpxvKcepWYlbZAawiEHbEnwIBQzwC8U5MR3vp28lXhsfa3RJ04yjMMfKzeAbhNYFMquKkvp1uDOmEDicqAXwSbZB4UEYVwaHcH20FkmtMi8adPjoVj58a3h29OwIHtwKkd2GIH3F1mP4Rkwb0c1OvvRR0pFKJ0wyglZBkXv2ruZAqfCY1XKyhP4L7QyiwtzNiIf0CA2shZCwy9dzb"
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
              :keyword => "keyword1", 
              :option0 => "204958204",
              :option1 => "230591204",
              :answer  => "230591204",
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
                       :quiz_uuid  => uuid,
                       :comment    => "test comment"}
    assert last_response.status == 204

    get '/comments', {:auth_token => @@token,
                      :quiz_uuid  => uuid}
    assert last_response.ok?
    array = JSON.parse(last_response.body)
    matches = array.select{|comment| comment["comment"] == "test comment"}            
    assert matches.count > 0
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