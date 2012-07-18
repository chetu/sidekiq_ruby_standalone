# Rsync based data backup script program using ruby 
#
# A pure safe backup program  
# rsync is incremental backup tools having variety of options like high rate compression, excludes, includes etc
# @chetanMM

== lib/rsync.rb: program for mail-config, read-config, compression-command, rsync-command 

== run.rb: compression-command, rsync-command sidekiq worker program

== Config folder resides multiple yamls for servers 

== Server addition is manual ssh-dss key based where servers has to puts dss keys in ~/.ssh/authorised_keys  
	- ssh-keygen -t dsa 									 # key generations for server where backup scripts running
	- then copy keys to backup server client 						 # please copy to respected user authorised to rsync data 
	  - append key to ~/.ssh/authorised_keys 
	    - cat serever.key.pub |ssh user@ip-address 'sh -c "cat - >>~/.ssh/authorized_keys2"' # manual from client server. 
	    - scp ~/.ssh/id_dsa.pub user@ip-address:/~.ssh/authorized_keys2 (update key with ssh-agent : ssh-agent sh -c 'ssh-add < /dev/null && bash' ) # remote key add 		
== Sidekiq sinatra wui : rackup -p 10002 -D

== Sidekiq test daemon : 
	- sidekiq -r ./run.rb -C 2 -p log/sidekiq.pid -q default > log/sidekiq.log & # start
	- kill -s INT `cat /path/to/sidekiq.pid 				     # stop 
	- irb -r ./run.rb 							     # irb testing on ruby console 
        - rake kick 								     # rake task for start sidekiq in daemon mode
== Clockwork scheduler generator :
	- rake gen_clock 
== Clockwork : clockwork clock.rb >log/clockwork.log &
