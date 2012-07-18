#! /usr/bin/env ruby
require 'sidekiq'
Dir["./lib/rsync.rb"].each {|file| require file }

Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'x', :url => 'redis://localhost:7878' }
end
Sidekiq.configure_client do |config|
  config.redis = { :url => 'redis://localhost:7878', :namespace => 'x', :size => 4 }
end


class RsyncWorker 
  include Sidekiq::Worker
  sidekiq_options :concurrency => 25
  sidekiq_options :environment => nil
  sidekiq_options :timeout => 64800
  sidekiq_options :enable_rails_extensions => false
  def perform(config_yml)
   p "am here #{config_yml}"
   rsync_instance = Rsync.new(config_yml)
   rsync_instance.read_config
   rsync_instance.take_backup
   rsync_instance.compress_daily	
 end
end
class ArchiveWorker
  include Sidekiq::Worker
  sidekiq_options :concurrency => 25
  sidekiq_options :environment => nil
  sidekiq_options :timeout => 64800
  sidekiq_options :enable_rails_extensions => false
  def perform(data_path,server_name,archive_schedule)
  p "am here for compression #{data_path} #{server_name} #{archive_schedule}"
  Archive.archive_on_schedule("#{data_path}","#{server_name}","#{archive_schedule}")
  end
end

class YmlProcess < Rsync   

  def generate_rsync_job(yml_file)
   @schedule.split(",").each(&:lstrip!).each do |single_schedule|
    case single_schedule

    when single_schedule = "hourly"
     doc = "\t every(1.hour, 'For #{yml_file}', :at => '**:30' ) do \n \t \t  RsyncWorker.perform_async(\"#{yml_file}\") \n  \t end \n" 
     File.open('./clock.rb','a') {|f| f.write(doc) }
    when single_schedule = "daily"
     doc = "\t every(1.day, 'For #{yml_file}', :at => '05:00' ) do \n \t \t RsyncWorker.perform_async(\"#{yml_file}\") \n  \t end \n" 
     File.open('./clock.rb','a') {|f| f.write(doc) }	
    when single_schedule = "weekly"
     doc = "\t every(1.week, 'For #{yml_file}', :at => '04:00') do \n \t \t RsyncWorker.perform_async(\"#{yml_file}\") \n \t end \n" 
     File.open('./clock.rb','a') {|f| f.write(doc) }
   end
 end
end



def generate_compress_schedule

  @folder_array.split(",").each(&:lstrip!).each do |folder|
#           if folder.split(":").length <= 1
#	   	p "nothing found re"
#	   else
if folder.split(":").length > 1
 sub_folder = folder.split(":").each(&:lstrip!)
 sub_folder[1].split("|").each(&:lstrip!).each do |archive_schedule|
  case archive_schedule

  when archive_schedule = "hourly"
    doc = "\t every(1.hour, 'For #{archive_schedule}', :at => '**:30' ) do \n \t \t  ArchiveWorker.perform_async(\"#{@backup_path.gsub(/\/$/, '')}#{sub_folder[0]}\",\"#{@server_name}\",\"#{archive_schedule}\") \n  \t end \n"
    File.open('./clock.rb','a') {|f| f.write(doc) }
  when archive_schedule = "daily"
    doc = "\t every(1.day, 'For #{archive_schedule}', :at => '15:00' ) do \n \t \t ArchiveWorker.perform_async(\"#{@backup_path.gsub(/\/$/, '')}#{sub_folder[0]}\",\"#{@server_name}\",\"#{archive_schedule}\") \n  \t end \n"
    File.open('./clock.rb','a') {|f| f.write(doc) }
  when archive_schedule = "weekly"
    doc = "\t every(1.week, 'For #{archive_schedule}', :at => '14:00') do \n \t \t ArchiveWorker.perform_async(\"#{@backup_path.gsub(/\/$/, '')}#{sub_folder[0]}\",\"#{@server_name}\",\"#{archive_schedule}\") \n  \t end \n"
    File.open('./clock.rb','a') {|f| f.write(doc) }
  end

end
end
end
end

end


def yml_process 
 yml_files = " "
 yml_files << `ls  ./config/*.yml |xargs`
 if yml_files.empty? 
   puts "Err list empty"	
 else
   doc = "# ClockWork scheduler generated at [#{Time.new}] \n require \"clockwork\" \n \n Dir[\"./lib/rsync.rb\"].each {|file| require file } \n Dir[\"./run.rb\"].each {|file| require file } \n \n module Clockwork \n handler do |job| \n \t puts \"Running \#{job}\" \n end  \n" 

   File.open('./clock.rb','w+') {|f| f.write(doc) }

   yml_files.split(" ").each do |yml_file|
     a = YmlProcess.new(yml_file)
     a.read_config
     a.generate_rsync_job(yml_file)
     a.generate_compress_schedule
   end
   File.open('./clock.rb','a') {|f| f.write("  end \n") }
 end
end
