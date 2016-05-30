require 'optparse'

require_relative 'library'
require_relative 'patron'
require_relative 'records'
require_relative 'utils'

module App

	def self.checkout_all(library, records, updates)
	  checkout = {}
	  errors = false

		records.patrons.each do |patron|
			# get updatable subs
			usubs = patron.subs & updates
			if not usubs.empty?
				library.log_out
		    library.log_in(patron)
				errors = false
		    if not library.logged_in?
		      errors = true
		      @@logger.error('login error for ' + patron.user_name)
		      next
		    end
				# checkout each sub
		    usubs.each do |id|
		      status = library.checkout(id)
					puts "#{id}: #{status}"
		      if status =~ /^ERR/i
		        @@logger.error("#{status} (#{patron.user_name} - #{id})")
		        errors = true
		      elsif status =~ /already/i
		        @@logger.error("#{status} (#{patron.user_name} - #{id})")
		      end
		      sleep(30)
		    end
			end
		end

	  errors
	end

	def self.subscribe(record)
	  catalogue = record.load_catalogue
		mags_by_id = {}
		catalogue.each { |m| mags_by_id[m.id] = m }
		record.patrons.each do |p|
			puts "\n[#{p.user_name}] ----"
			p.subs.each do |s|
				if mags_by_id.has_key?(s)
					puts mags_by_id[s]
				else
					puts "Not found: #{s}"
				end
			end
		end
	end

	def self.catalogue(library, records)
	  previous = records.load_catalogue
		current = library.build_catalogue
		if current.length <= 0
			@@logger.error("Error building live catalogue")
		end
		records.save_catalogue(previous, true)
		records.save_catalogue(current, false)
		change = current.length - previous.length
		if change != 0
			@@logger.info("Magazine selection has changed (#{change})")
			log_change(previous, current)
		end
	end

	def self.update(library, records)
		updates = []
		message = ''
		previous = records.load_catalogue
		current = library.build_catalogue
		subscriptions = records.subscriptions

	  current.each do |mag|
	    # find updated magazines
	    unless previous.include? mag
	      # that are subscribed to
	      if subscriptions.include? mag.id
					updates << mag.id
	        message += mag.title + ', '
				end
	    end
	  end
	  errors = checkout_all(library, records, updates)
	  unless errors
	    @@logger.info(message) unless message.empty?
			records.save_catalogue(previous, true)
			records.save_catalogue(current, false)
	  end
	end

	def self.main()
	  options = {}
	  OptionParser.new do |opts|
	    opts.banner = 'Usage: start.rb [options]'
	    # show subscriptions by user & title
	    opts.on('-s', '--subscriptions') { options[:subscriptions] = true }
			# rebuild catalogue and compare with previous version
	    opts.on('-c', '--catalogue') { options[:catalogue] = true }
			# update all patron subscriptions and checkout if any new
	    opts.on('-u', '--update') { options[:update] = true }
	  end.parse!

		# load config
		records = App::Records.instance
		config_file = File.expand_path('config.yaml', File.join(File.dirname(__FILE__), '..'))
		records.load(config_file)
		if records.settings.nil? || records.patrons.nil?
			puts "Configuration file is invalid (missing required sections)"
			return
		end

		 @@logger = Logger.new(
		 	records.settings['log_file'], LogLevel::DEBUG)

	  # set up objects
	  library = App::Library.new(
	    records.settings["landing_page"], records.settings["library_id"])

		# perform actions
		update(library, records) if options[:update]
	  subscribe(records) if options[:subscriptions]
		catalogue(library, records) if options[:catalogue]

	end

	private

		def self.log_change(previous, current)
			prev_hash = {}
			current_hash = {}
			previous.each { |p| prev_hash[p.id] = p.title }
			current.each { |c| current_hash[c.id] = c.title }
			current_hash.each_pair do |k,v|
				if !prev_hash.has_key?(k)
					@@logger.info("NEW: #{v} (#{k})")
				end
			end
			prev_hash.each_pair do |k,v|
				if !current_hash.has_key?(k)
					@@logger.info("DEL: #{v} (#{k})")
				end
			end
		end

end

if __FILE__ == $0
		App::main
end
