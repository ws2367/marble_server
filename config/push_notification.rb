# @@apn = Houston::Client.development
# @@apn.certificate = File.read("config/apn_development_marble.pem")


# def send_push_notification user, alert, badge, custom_data
#   if user.device_token != nil
#     notification = Houston::Notification.new(device: user.device_token)
#     notification.alert = alert
#     notification.badge = badge
#     if custom_data != nil
#       notification.content_available = true
#       notification.custom_data = custom_data
#     end

#     @@apn.push(notification)  
#     puts "Notification is sent to user #{user.name}"
#   end
# end