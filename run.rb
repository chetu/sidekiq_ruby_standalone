#! /usr/bin/env ruby
require 'sidekiq'
Dir["./lib/rsync.rb"].each {|file| require file }

Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'x', :url => 'redis://localhost:7878' }
end
Sidekiq.configure_client do |config|
  config.redis = { :url => 'redis://localhost:7878', :namespace => 'x', :size => 4 }
end


class MyWorker 
  include Sidekiq::Worker
# timeout must be more for rsync operations
    sidekiq_options :concurrency => 25
    sidekiq_options :environment => nil
    sidekiq_options :timeout => 64800
    sidekiq_options :enable_rails_extensions => false
  def perform(config_yml)
   p "am here #{config_yml}"
   rsync_instance = Rsync.new(config_yml)
   rsync_instance.read_config
   rsync_instance.take_backup
   #rsync_instance.compress_daily	
  end
end
class Yml_process < Rsync   

    def generate_job(yml_file)
         @schedule.split(",").each(&:lstrip!).each do |single_schedule|
          case single_schedule

           when single_schedule = "hourly"
	        doc = "\t every(1.hour, 'For \"#{yml_file}\"') do \n \t \t  MyWorker.perform_async(\"#{yml_file}\") \n  \t end \n" 
		File.open('./clock.rb','a') {|f| f.write(doc) }
           when single_schedule = "daily"
	        doc = "\t every(1.day, 'For \"#{yml_file}\"') do \n \t \t MyWorker.perform_async(\"#{yml_file}\") \n  \t end \n" 
	        File.open('./clock.rb','a') {|f| f.write(doc) }	
           when single_schedule = "weekly"
	        doc = "\t every(1.week, 'For \"#{yml_file}\"') do \n \t \t MyWorker.perform_async(\"#{yml_file}\") \n \t end \n" 
                File.open('./clock.rb','a') {|f| f.write(doc) }
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
	  a = Yml_process.new(yml_file)
	  a.read_config
	  a.generate_job(yml_file)
	end
	File.open('./clock.rb','a') {|f| f.write("  end \n") }
       end
 end
