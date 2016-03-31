require_relative "app"

App.config("config.yaml")

LOG_FILE = File.expand_path(App.settings["log_file"], File.join(File.dirname(__FILE__), '..'))

def log(message)
  log_string = Time.now.strftime('[%Y-%m-%d %H:%M:%S] ') + message + "\n"
  File.open(LOG_FILE, 'a+') do |f|
    f.write(log_string)
  end
end
