# ClockWork scheduler generated at [2012-07-17 13:35:47 +0530] 
 require "clockwork" 
 
 Dir["./lib/rsync.rb"].each {|file| require file } 
 Dir["./run.rb"].each {|file| require file } 
 
 module Clockwork 
 handler do |job| 
 	 puts "Running #{job}" 
 end  
	 every(1.day, 'For "./config/1.yml"') do 
 	 	 MyWorker.perform_async("./config/1.yml") 
  	 end 
	 every(1.hour, 'For "./config/1.yml"') do 
 	 	  MyWorker.perform_async("./config/1.yml") 
  	 end 
	 every(1.day, 'For "./config/2.yml"') do 
 	 	 MyWorker.perform_async("./config/2.yml") 
  	 end 
	 every(1.day, 'For "./config/3.yml"') do 
 	 	 MyWorker.perform_async("./config/3.yml") 
  	 end 
  end 
