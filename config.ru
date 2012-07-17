require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { :url => 'redis://localhost:7878', :namespace => 'x', :size => 4 }
end



require 'sidekiq/web'
run Sidekiq::Web
