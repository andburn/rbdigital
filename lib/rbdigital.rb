require "log4r"

require "rbdigital/version"
require "rbdigital/library"
require "rbdigital/errors"

module Rbdigital
  # set global logger base level
  Log4r::Logger.root.level = Log4r::WARN

  @@library = nil
  @@logger = nil

  def self.library
    if @@library.nil?
      raise LibraryError.new("library object is nil")
    end
    return @@library
  end

  def self.set_library(code, id)
    @@library = Library.new(code, id)
  end

  def self.logger
    if @@logger.nil?
      @@logger = Log4r::Logger.new("rbdigital")
      # add a default console output
      @@logger.add(Log4r::StderrOutputter.new("console"))
    end
    @@logger
  end

  def self.set_log_level(level)
    self.logger.level = level
    Log4r::Logger.root.level = level
    Log4r::Outputter.each {|k,v| v.level = level}
  end

  def self.add_file_logger(log_file, level=Log4r::INFO)
    name = "logfile"
    if Log4r::Outputter[name].nil?
      # add a file outputter to logger if arg is ok
      if not log_file.nil? && Dir.exist?(File.dirname(log_file))
        file_output = Log4r::FileOutputter.new(name,
          :filename => log_file,
          :trunc => false,
          :level => level,
          :formatter => Log4r::PatternFormatter.new(pattern: "%d %l: %m"))
        self.logger.add(file_output)
      end
    else
      self.logger.warn 'logfile outputter already exists'
    end
  end
end
