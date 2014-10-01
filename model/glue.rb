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

  def self.list
    @@glues.inspect
  end
end