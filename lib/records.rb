require 'singleton'
require 'yaml'
require_relative 'patron'
require_relative 'magazine'

module App

  class Records

    include Singleton

    attr_reader :config_file, :catalogue_file, :log_file

    def load(file)
      @config_file = file
      @config = YAML.load_file(file)
      @catalogue_file = nil
      if @config.has_key?('settings') && @config['settings'].has_key?('catalogue_file')
        @catalogue_file = File.expand_path(
          @config['settings']['catalogue_file'],
          File.join(File.dirname(__FILE__), '..'))
      end
      @log_file = nil
      if @config.has_key?('settings') && @config['settings'].has_key?('log_file')
        @log_file = File.expand_path(
          @config['settings']['log_file'],
          File.join(File.dirname(__FILE__), '..'))
      end
    end

    def save(file)
      File.open(file, 'w') do |out|
        YAML.dump(@config, out)
      end
    end

    def settings
      if @config.has_key?("settings")
        return @config["settings"]
      end
      nil
    end

    def patrons
      pats = []
      if @config.has_key?("patrons")
        @config["patrons"].each do |p|
          if p.keys.length == 1
            key = p.keys[0]
            pats << Patron.new(key,
              p[key]["email"], p[key]["password"], p[key]["subscriptions"])
          end
        end
      end
      pats
    end

    def get_patron(name)
      if @config["patrons"].has_key?(name)
        p = @config["patrons"][name]
        return Patron.new(name, p["email"], p["password"], p["subscriptions"])
      end
      nil
    end

    def subscriptions
      subs = []
      unless patrons.nil?
        patrons.each do |p|
          subs = subs | p.subs
        end
      end
      subs
    end

    def save_catalogue(catalogue, backup=false)
      file = backup ? @catalogue_file + ".bak" : @catalogue_file
      output = ''
      catalogue.each do |mag|
        output += "#{mag.id};#{mag.title};#{mag.cover_id}\n"
      end
      unless output.empty?
        write_to_file(file, output, false)
      end
    end

    def load_catalogue
      magazines = []
      catalogue = load_file_to_array(@catalogue_file)
      unless catalogue.nil?
        catalogue.each do |c|
          m = c.split(/;/)
          next unless m.length == 3
          magazines << Magazine.new(m[1], m[0], m[2])
        end
      end
      magazines
    end

    private

      def write_to_file(filename, text, append=true)
        mode = append ? 'a' : 'w'
        File.open(filename, mode) do |f|
          f.write(text)
        end
      end

      def load_file_to_array(filename)
        return nil unless File.exist?(filename)
        File.open(filename, 'r').readlines
      end

  end

end
