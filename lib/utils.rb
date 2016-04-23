module App

  class Logger

    attr_reader :level, :file

    def initialize(log_file=nil, level=LogLevel::DEBUG)
      @level = level
      config_log_file = 'log.txt'
      config_log_file = log_file unless log_file.nil?
      @file = File.expand_path(config_log_file, File.join(File.dirname(__FILE__), '..'))
    end

    def log(message, level=LogLevel::DEBUG)
      log_string = Time.now.strftime('[%Y-%m-%d %H:%M:%S] ') + message + "\n"
      File.open(@file, 'a+') do |f|
        f.write(log_string)
      end
    end

    def debug(message)
      log(message, LogLevel::DEBUG)
    end

    def info(message)
      log(message, LogLevel::INFO)
    end

    def error(message)
      log(message, LogLevel::ERROR)
    end

  end

  class LogLevel
    DEBUG = 0
    INFO = 1
    ERROR = 2
  end

end
