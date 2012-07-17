
  #!/usr/bin/env ruby
  # Backup automation program using rsync
  # client must authorised with dss key for passwordless rsync 
  require 'logger'
  require 'yaml'
  require 'mail'  
  Dir["./mailer.rb"].each {|file| require file }
  @@log = Logger.new( 'log/rsync.log', 'daily' )
  @@t = Time.new
  @@date_time = "#{@@t.year}-#{@@t.month}-#{@@t.day}"
  class Rsync
    attr_accessor :server_name, :ipaddress, :password, :username, :port, :folder_array , :backup_path , :exclude_array, :schedule

  def initialize(config_name)
    @config_name = config_name
  end
  # reads given argument as yml
  def read_config
    config = YAML.load_file("#{@config_name}")
    @server_name = config["config"]["server_name"]
    @username = config["config"]["username"]
    @port = config["config"]["port"]
    @ipaddress = config["config"]["ipaddress"]
    @password = config["config"]["password"]
    @folder_array = config["config"]["folder_array"]
    @backup_path = config["config"]["backup_path"]
    @exclude_array = config["config"]["exclude_array"]
    @schedule = config["config"]["schedule"]
  end
  def take_backup
   @@log.debug "backup...started for #{@ipaddress} at [#{Time.new}]"
   @folder_array.split(",").each(&:lstrip!).each do |folder|
     @exclude_final= ""
     @exclude_array.split(",").each(&:lstrip!).each do |exclude|
       @exclude_final =  @exclude_final + ' --exclude \'' + exclude + '\''
     end   
    cmd = "rsync -Ravzrq --skip-compress=*.tgz,*.gz,*.bz2,*.iso,*.jpg,*.jpeg,*.tif,*.tiff,*.tar,*.zip,*.mov,*.png,*.gif --delete #{@exclude_final} -e 'ssh -p#{@port}' #{@username}@#{@ipaddress}:#{folder} #{@backup_path}"
     # system execution command for rsync 
     %x{#{cmd}}  
   end
   @@log.debug "backup...completed for #{@ipaddress} at [#{Time.new}]"
 end
 def compress_daily
  tar_cmd = "tar -zcvf #{@backup_path}.[#{@@date_time}].tar.gz #{@backup_path} && cd -"
   @@log.debug "Started daily compression #{@ipaddress} at [#{Time.new}]"
  p tar_cmd
  %x{#{tar_cmd}} 
   @@log.debug "Completed daily compression #{@ipaddress} at [#{Time.new}]"
end

end


