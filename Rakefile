# Rakefile
require "sinatra/activerecord/rake"
require "./main"
import "task/test.rake"


namespace :db do

  desc "create a fake quiz"
  task :create_quiz do
    opt0, opt1, quiz = Quiz.create_quiz_dependencies({
                        author_name: params[:author_name], 
                        keyword: params[:keyword], 
                        option0: params[:option0], 
                        option0_name: params[:option0_name],
                        option1: params[:option1],  
                        option1_name: params[:option1_name],
                        answer:  params[:answer],
                        uuid:    params[:uuid]}, user)
  end
end
 
