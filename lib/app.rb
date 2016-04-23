require 'optparse'

require_relative 'library'
require_relative 'patron'
require_relative 'records'
require_relative 'utils'

module App


	def self.checkout_all(library, storage, list)
	  checkout = {}
	  errors = false
	  list.each do |l|
	    e = l.split(/,/)
	    if e.length == 3
	      names = e[2].split(/:/)
	      names.each do |n|
	        if checkout.key?(n)
	          checkout[n] << e[0]
	        else
	          checkout[n] = [e[0]]
	        end
	      end
	    end
	  end
	  # login in for each and checkout
	  checkout.each_key do |p|
	    patron = storage.get_patron(p)
	    library.log_out
	    library.log_in(patron)
	    # TODO doesn't seem necessary!
	    errors = true unless library.logged_in?
	    if not library.logged_in?
	      errors = true
	      log 'login error for ' + patron.user_name
	      # TODO should probably return here too
	    end
	    # for each subscribed checkout
	    checkout[p].each do |id|
	      status = library.checkout(id)
	      if status =~ /^ERR/i
	        log "#{status} (#{patron.user_name} - #{id})"
	        errors = true
	      elsif status =~ /already/i
	        log "#{status} (#{patron.user_name} - #{id})"
	      end
	      sleep(20)
	    end
	  end
	  errors
	end

	def self.subscribe(record)
	  catalogue = record.load_catalogue
		mags_by_id = {}
		catalogue.each { |m| mags_by_id[m.id] = m }
		record.patrons.each do |obj|
			obj.each do |k,v|
				puts "---- #{k}"
				v["subscriptions"].each do |s|
					if mags_by_id.has_key?(s)
						puts mags_by_id[s]
					else
						puts "Not found: #{s}"
					end
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
		end
	end

	def self.update(library, records)
		previous = records.load_catalogue
		current = library.build_catalogue
	  updates = []
	  message = ''
	  current.each do |mag|
	    # find updated magazines
	    unless previous.include? mag
	      # that are subscribed to
	      sub = storage.get_subscription(mag.id)
	      unless sub.nil?
	        updates << sub
	        message += mag.title + ', '
	      end
	    end
	  end
	  errors = checkout_all(library, storage, updates)
	  unless errors
	    log(message) unless message.empty?
	    storage.save_catalogue(current)
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
			records.settings['log_file'], LogLevel::INFO)

	  # set up objects
	  library = App::Library.new(
	    records.settings["landing_page"], records.settings["library_id"])

		# perform actions
		update(library, records) if options[:update]
	  subscribe(records) if options[:subscriptions]
		catalogue(library, records) if options[:catalogue]

	end

end

if __FILE__ == $0
		App::main
end
