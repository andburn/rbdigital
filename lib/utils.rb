module App

  class Logger

    include Singleton

    attr_accessor :level, :file

    def initialize
      # set default attribs
      @level = LogLevel::DEBUG
      @file = 'log.txt'
    end

    def log(message, level=LogLevel::DEBUG)
      return if level < @level
      return unless File.exist?(@file)
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
