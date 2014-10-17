namespace :test do
  desc "Send fake notifications"
  task :notify do
    user_id = 1
    puts "[RAKE] -- fake notifications for user #{user_id}" 

    user = User.find_by_id(user_id)
    a = User.last
    uuid = UUIDTools::UUID.random_create.to_s
    opt0, opt1 = Quiz.create_quiz_dependencies({
                author_name: "TestFirst TestLast", 
                keyword: "Test Keyword", 
                option0: user.fb_id, 
                option0_name: user.name,
                option1: "34677",  
                option1_name: "Test option1",
                answer:  user.name,
                uuid:    uuid}, a)
    
    opt0.increment_badge_number
    opt1.increment_badge_number

    # alert = "#{user.name} compared you"
    # send_push_notification opt0, alert, opt0.badge_number, {post_uuid: uuid}
    # send_push_notification opt1, alert, opt1.badge_number, {post_uuid: uuid}

  end
end