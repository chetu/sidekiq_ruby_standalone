# ClockWork scheduler generated at [2012-07-26 09:48:01 +0530] 
 require "clockwork" 
 
 Dir["./lib/rsync.rb"].each {|file| require file } 
 Dir["./run.rb"].each {|file| require file } 
 
 module Clockwork 
 handler do |job| 
 	 puts "Running #{job}" 
 end  
	 every(1.day, 'For BulkarchiveWorker', :at => '05:30' ) do 
 	 	 BulkarchiveWorker.perform_async("./config/test1.yml") 
  	 end 
	 every(1.hour, 'For RsyncWorker', :at => '**:30' ) do 
 	 	  RsyncWorker.perform_async("./config/test1.yml") 
  	 end 
	 every(1.day, 'For BulkarchiveWorker', :at => '02:35' ) do 
 	 	 BulkarchiveWorker.perform_async("./config/test2.yml") 
  	 end 
	 every(1.hour, 'For RsyncWorker', :at => '**:20' ) do 
 	 	  RsyncWorker.perform_async("./config/test2.yml") 
  	 end 
	 every(1.day, 'For RsyncWorker', :at => '05:30' ) do 
 	 	 RsyncWorker.perform_async("./config/test2.yml") 
  	 end 
	 every(1.day, 'For BulkarchiveWorker', :at => '04:00' ) do 
 	 	 BulkarchiveWorker.perform_async("./config/test3.yml") 
  	 end 
	 every(1.hour, 'For RsyncWorker', :at => '**:10' ) do 
 	 	  RsyncWorker.perform_async("./config/test3.yml") 
  	 end 
  end 
