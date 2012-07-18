
  #!/usr/bin/env ruby
  # Backup automation program using rsync
  # client must authorised with dss key for passwordless rsync 
  require 'logger'
  require 'yaml'
  require 'mail'  
  Dir["./mailer.rb"].each {|file| require file }
  @@log = Logger.new( 'log/rsync.log', 'daily' )
  @@date_time = "#{Time.now.strftime("%Y-%m-%d-%H%M%S")}"
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
     sub_folder = folder.split(":").each(&:lstrip!)
     @exclude_final= ""
     @exclude_array.split(",").each(&:lstrip!).each do |exclude|
       @exclude_final =  @exclude_final + ' --exclude \'' + exclude + '\''
     end   
     cmd = "rsync -Ravzrq --skip-compress=tgz/gz/bz2/7z/bz2/iso/jpg/jpeg/tif/tiff/tar/zip/mov/png/gif/mp[34] --delete #{@exclude_final} -e 'ssh -p#{@port}' #{@username}@#{@ipaddress}:#{sub_folder[0]} #{@backup_path}"
     # system execution command for rsync 
     %x{#{cmd}}  
     p cmd
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
class Archive < Rsync

 def self.archive_on_schedule(data_path,server_name,archive_schedule)
  s_tar_cmd = "tar -zcvf Archives/#{server_name}#{data_path.gsub(/\//, '-')}-#{archive_schedule}.#{Time.now.strftime("%Y-%m-%d-%H%M%S")}.tar.gz #{data_path} "
  p s_tar_cmd
  %x{#{s_tar_cmd}}
  
end

end

## TEST 
#rsync_instance = Archive.new("./config/ishy.yml")
#rsync_instance.read_config
#rsync_instance.archive_on_schedule("/data/current_backups/ishy/backup/mybackupsql","test","hourly")

#Archive.archive_on_schedule("/data/current_backups/ishy/backup/mybackupsql","test","hourly")


