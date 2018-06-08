require "log4r"

require "rbdigital/version"
require "rbdigital/library"

module Rbdigital
  # set global logger base level
  Log4r::Logger.root.level = Log4r::WARN

  @@logger = nil

  def self.logger
    if @@logger.nil?
      @@logger = Log4r::Logger.new("rbdigital")
      # add a default console output
      @@logger.add(Log4r::StderrOutputter.new("console"))
    end
    @@logger
  end

  def self.log_to_file(log_file)
    # add a file outputter to logger if arg is ok
    if not log_file.nil? && File.file?(log_file)
      file_output = Log4r::FileOutputter.new("logfile",
        :filename => log_file,
        :trunc => false,
        :level => Log4r::ERROR)
      self.logger.add(file_output)
    end
  end
end
