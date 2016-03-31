require "yaml"

module App

		@@settings = {}
		@@patrons = {}

		def self.config(file)
			if @@settings.empty? || @@patrons.empty?
				yaml = YAML.load_file(file)
				@@settings = yaml["settings"]
				@@patrons = yaml["patrons"]
			end
		end

		def self.settings
			@@settings
		end

		def self.patrons
			@@patrons
		end

end
