def read_credentials
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

read_credentials