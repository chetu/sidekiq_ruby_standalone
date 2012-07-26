require 'rake'
require 'bundler'
Bundler.setup
Bundler.require(:default) if defined?(Bundler)



Dir["./lib/rsync.rb"].each {|file| require file }
Dir["./run.rb"].each {|file| require file }

task :hi do 
  desc "HI Welcome To Server Backup program"
  print "please try 'rake --tasks' to see all task \n"
end

task :default  => [:hi]

  desc "generate schedule for clockwork"
  task :gen_clock do
     yml_process
  end
 
  desc "start sidekiq daemon"
  task :kick do
    ` sidekiq -r ./run.rb -C 2 -p log/sidekiq.pid -q default >log/sidekiq.log &`
  end
  desc "start clockwork daemon"  
  task :start_clock do
   `clockwork clock.rb >log/clockwork.log &`
  end
  desc "restart all"
  task :kickstart do
   `pii side |xargs kill -9 && pii clock |xargs kill -9 && redis-cli -p 7878 flushall && rake gen_clock && rake kick && rake start_clock` 
  end 
