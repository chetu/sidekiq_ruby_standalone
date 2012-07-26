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
   p "IN RSYNC #{config_yml}"
   rsync_instance = Rsync.new(config_yml)
   rsync_instance.read_config
   rsync_instance.take_backup
 end
end

class BulkarchiveWorker
  include Sidekiq::Worker
  sidekiq_options :concurrency => 25
  sidekiq_options :environment => nil
  sidekiq_options :timeout => 64800
  sidekiq_options :enable_rails_extensions => false
  def perform(config_yml)
   p "IN BULK_ARCHIVE #{config_yml}"
   rsync_instance = Rsync.new(config_yml)
   rsync_instance.read_config
   rsync_instance.compress_daily        
 end
end


class ArchiveWorker
  include Sidekiq::Worker
  sidekiq_options :concurrency => 25
  sidekiq_options :environment => nil
  sidekiq_options :timeout => 64800
  def perform(data_path,server_name,custom_archive_schedule)
     p "IN ARCHIVE #{data_path} #{server_name} #{custom_archive_schedule}"
     Archive.archive_on_schedule("#{data_path}","#{server_name}","#{custom_archive_schedule}")
  end
end

class YmlProcess < Rsync   

  def generate_job(yml_file,worker_name)
      # schedule for bulkarchive is static 
      if worker_name == 'BulkarchiveWorker'
        @archive_schedule.split(",").each(&:lstrip!).each do |single_schedule|
        s_single_schedule = single_schedule.split("|").each(&:lstrip!)
	a = s_single_schedule[0]
        case a
         when a = "hourly"
          if single_schedule.split("|").length > 1
            s_time = s_single_schedule[1]
          else
           s_time = "**:30"
          end
          doc = "\t every(1.hour, 'For #{worker_name}', :at => '#{s_time}' ) do \n \t \t  #{worker_name}.perform_async(\"#{yml_file}\") \n  \t end \n"
          File.open('./clock.rb','a') {|f| f.write(doc) }
         when a = "daily"
          if single_schedule.split("|").length > 1
            s_time = s_single_schedule[1]
          else    
             s_time = "05:30"
          end
          doc = "\t every(1.day, 'For #{worker_name}', :at => '#{s_time}' ) do \n \t \t #{worker_name}.perform_async(\"#{yml_file}\") \n  \t end \n"
          File.open('./clock.rb','a') {|f| f.write(doc) }
         when a = "weekly"
          if single_schedule.split("|").length > 1
            s_time = s_single_schedule[1]
          else
            s_time = "04:00"
          end
          doc = "\t every(1.week, 'For #{worker_name}', :at => '#{s_time}') do \n \t \t #{worker_name}.perform_async(\"#{yml_file}\") \n \t end \n"
          File.open('./clock.rb','a') {|f| f.write(doc) }
        end
       end
     
    else
      if worker_name == 'RsyncWorker'
        @rsync_schedule.split(",").each(&:lstrip!).each do |single_schedule|
        s_single_schedule = single_schedule.split("|").each(&:lstrip!)
  	a = s_single_schedule[0]		
	case a
        when a = "hourly"
          if single_schedule.split("|").length > 1
	   s_time = s_single_schedule[1]
	 else
           s_time = "**:30"
          end
          doc = "\t every(1.hour, 'For #{worker_name}', :at => '#{s_time}' ) do \n \t \t  #{worker_name}.perform_async(\"#{yml_file}\") \n  \t end \n" 
          File.open('./clock.rb','a') {|f| f.write(doc) }
        when a = "daily"
         if single_schedule.split("|").length > 1
          s_time = s_single_schedule[1]
         else
          s_time = "05:30"
         end
         doc = "\t every(1.day, 'For #{worker_name}', :at => '#{s_time}' ) do \n \t \t #{worker_name}.perform_async(\"#{yml_file}\") \n  \t end \n" 
         File.open('./clock.rb','a') {|f| f.write(doc) }  
        when a = "weekly"
         if single_schedule.split("|").length > 1
          s_time = s_single_schedule[1]
         else
          s_time = "04:30"
         end
         doc = "\t every(1.week, 'For #{worker_name}', :at => '#{s_time}') do \n \t \t #{worker_name}.perform_async(\"#{yml_file}\") \n \t end \n" 
         File.open('./clock.rb','a') {|f| f.write(doc) }
        end
      end
     end
  end
end
  def generate_compress_schedule
    @folder_array.split(",").each(&:lstrip!).each do |folder|
    if folder.split("|").length > 1
    sub_folder = folder.split("|").each(&:lstrip!)
    sub_folder[1].split("|").each(&:lstrip!).each do |custom_archive_schedule|

        case custom_archive_schedule

        when custom_archive_schedule = "hourly"
          doc = "\t every(1.hour, 'For #{custom_archive_schedule}', :at => '**:30' ) do \n \t \t  ArchiveWorker.perform_async(\"#{@backup_path.gsub(/\/$/, '')}#{sub_folder[0]}\",\"#{@server_name}\",\"#{custom_archive_schedule}\") \n  \t end \n"
          File.open('./clock.rb','a') {|f| f.write(doc) }
        when custom_archive_schedule = "daily"
          doc = "\t every(1.day, 'For #{custom_archive_schedule}', :at => '15:00' ) do \n \t \t ArchiveWorker.perform_async(\"#{@backup_path.gsub(/\/$/, '')}#{sub_folder[0]}\",\"#{@server_name}\",\"#{custom_archive_schedule}\") \n  \t end \n"
          File.open('./clock.rb','a') {|f| f.write(doc) }
        when custom_archive_schedule = "weekly"
          doc = "\t every(1.week, 'For #{custom_archive_schedule}', :at => '14:00') do \n \t \t ArchiveWorker.perform_async(\"#{@backup_path.gsub(/\/$/, '')}#{sub_folder[0]}\",\"#{@server_name}\",\"#{custom_archive_schedule}\") \n  \t end \n"
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
     a.generate_job(yml_file,"BulkarchiveWorker")
     a.generate_job(yml_file,"RsyncWorker")
     a.generate_compress_schedule
   end
   File.open('./clock.rb','a') {|f| f.write("  end \n") }
  end
end


