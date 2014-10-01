# @@glues[uuid] = [
#                    {author:xxx, keyword:xx, option0:xx, option1:xx, answer:xx, time:xx},
#                   ]

  # glue = {author:xxx, keyword:xx, option0:xx, option1:xx, answer:xx, time:xx}
  
# class Librarian
#   def initialize
#     @glues = Hash.new
#   end

#   def create_glue glue
#     # uuid = UUIDTools::UUID.random_create.to_s
#     # @glues[uuid] = glue 
#     # puts @glues.inspect
#     # return uuid
#   end

# end

# require './model/user.rb'

class Glue
  @@glues = Array.new

  def initialize glue
    @uuid    = UUIDTools::UUID.random_create.to_s
    @author  = glue["author"]
    @keyword = glue["keyword"]
    @option0 = glue["option0"]
    @option1 = glue["option1"]
    @time    = Time.now
    @@glues << self
  end
end