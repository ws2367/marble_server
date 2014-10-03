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