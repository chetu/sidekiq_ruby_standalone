# Rsync based data backup script program using ruby 
#
# A pure safe backup program without any recovery 
# rsync is incremental backup tools having variety of options like high rate compression, excludes, includes etc
# 

	lib/rsync.rb: program for mail-config, read-config, compression-command, rsync-command 

        run.rb: compression-command, rsync-command sidekiq worker program

	config folder resides multiple yamls for servers 

	server addition is manual ssh-dss key based where servers has to puts dss keys in ~/.ssh/authorised_keys  

	sidekiq sinatra wui : rackup -p 10002 -D

	sidekiq test daemon : 
		-- sidekiq -r ./run.rb -C 2 -p log/sidekiq.pid -q default > log/sidekiq.log &
		-- to test WorKer with sidekiq standalone irb : irb -r ./run.rb 
        	- rake kick # task for starting sidekiq daemon
	 clockwork scheduler generator :
		- rake gen_clock 
	 clockwork : clockwork clock.rb >log/clockwork.log &

