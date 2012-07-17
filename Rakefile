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
    ` sidekiq -r ./run.rb -C 2 -p log/sidekiq.pid -q default > log/sidekiq.log &`
  end
  desc "start clockwork daemon"  
  task :start_clock do
   `clockwork clock.rb >log/clockwork.log &`
  end

