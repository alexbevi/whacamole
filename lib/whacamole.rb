require 'whacamole/config'
require 'whacamole/events'
require 'whacamole/heroku_wrapper'
require 'whacamole/stream'

module Whacamole

  @@config = {}

  def self.configure(app_name)
    @@config[app_name.to_s] ||= Config.new(app_name)
    yield @@config[app_name.to_s]
  end

  def self.monitor
    threads = []
    @@config.each do |app_name, config|
      threads << Thread.new do
        heroku = HerokuWrapper.new(app_name, config.api_token, config.dynos, config.restart_window)

        while true
          stream_url = heroku.create_log_session
          puts "#{app_name} | #{stream_url}"
          begin
            Stream.new(stream_url, heroku, config.restart_threshold, &config.event_handler).watch
          rescue => ex
            puts "#{app_name} - restarting monitoring (#{ex.message})"
          end
        end
      end
    end
    threads.collect(&:join)
  end
end
