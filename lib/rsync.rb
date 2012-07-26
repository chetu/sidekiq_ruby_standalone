#!/usr/bin/env ruby
# Backup automation program using rsync
# client must authorised with dss key for passwordless rsync 
  require 'logger'
  require 'yaml'
  require 'mail'  
  require 'open3' 
  Dir["./mailer.rb"].each {|file| require file }
  @@log = Logger.new( 'log/rsync.log', 'daily' )
  @@date_time = "#{Time.now.strftime("%Y-%m-%d-%H%M%S")}"
  @@date = "#{Time.now.strftime("%Y-%m-%d")}"
  class Rsync
    attr_accessor :server_name, :ipaddress, :password, :username, :port, :folder_array , :backup_path , :exclude_array, :rsync_schedule, :archive_schedule

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
    @rsync_schedule = config["config"]["rsync_schedule"]
    @archive_schedule = config["config"]["archive_schedule"]
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
     stdin, stdout, stderr = Open3.popen3("#{cmd}") 
     if  stderr
	@@log.debug "#{stderr.readlines}"
     end 
     p cmd
   end
   @@log.debug "backup...completed for #{@ipaddress} at [#{Time.new}]"
 end
 def compress_daily
  sza_cmd = "mkdir -p BulkArchives/#{@@date} && 7za a -t7z -mmt -mx9 BulkArchives/#{@@date}/#{@server_name}.7z #{@backup_path}"
  #tar_cmd = "mkdir -p BulkArchives/#{@@date} && tar -zcvf BulkArchives/#{@@date}/#{@server_name}.tar.gz #{@backup_path} "
   @@log.debug "Started daily compression #{@ipaddress} at [#{Time.new}]"
#  p tar_cmd
  p sza_cmd
  #%x{#{tar_cmd}} 
  %x{#{sza_cmd}} 
   @@log.debug "Completed daily compression #{@ipaddress} at [#{Time.new}]"
 end
end
class Archive < Rsync

 def self.archive_on_schedule(data_path,server_name,archive_schedule)
        #s_tar_cmd = "mkdir -p Archives/#{@@date_time} && tar -zcvf Archives/#{@@date_time}/#{server_name}#{data_path.gsub(/\//, '-')}-#{archive_schedule}.tar.gz #{data_path} "
       s_7za_cmd = "mkdir -p Archives/#{@@date_time} && 7za a -t7z -mmt -mx9 Archives/#{@@date_time}/#{server_name}#{data_path.gsub(/\//, '-')}-#{archive_schedule}.7z #{data_path} "
        #p s_tar_cmd
        p s_7za_cmd
	#%x{#{s_tar_cmd}}
	%x{#{s_7za_cmd}}
 end

end


