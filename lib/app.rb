require 'optparse'

require_relative 'library'
require_relative 'patron'
require_relative 'records'
require_relative 'utils'

module App

	def self.checkout_all(library, records, updates)
	  checkout = {}
	  errors = false

		puts "#{updates.length} updates"
		records.patrons.each do |patron|
			puts "User: #{patron.name}"
			# get updatable subs
			usubs = patron.subs & updates
			puts "Updates: #{usubs}"
			if not usubs.empty?
				library.log_out
		    library.log_in(patron)
				errors = false
		    if not library.logged_in?
		      errors = true
		      @@logger.error('login error for ' + patron.user)
		      next
		    end
				# checkout each sub
		    usubs.each do |id|
					puts "Checking out #{id}"
					# need to sleep between checkouts or errors
					sleep(30)
					# checkout the latest issue
		      status = library.checkout(id)
		      if status =~ /^ERR/i
		        @@logger.error("#{status} (#{patron.name} - #{id})")
		        errors = true
					# doesn't seem to happen anymore
		      elsif status =~ /already/i
		        @@logger.error("#{status} (#{patron.name} - #{id})")
		      end
		    end
			end
		end

	  errors
	end

	def self.subscriptions(record)
		catalogue = record.load_catalogue
		mags_by_id = {}
		catalogue.each { |m| mags_by_id[m.id] = m }
		record.patrons.each do |p|
			puts "\n[#{p.name}] ----"
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

	def self.get_updated(library, records)
		updates = []
		message = ''
		previous = records.load_catalogue
		current = library.build_catalogue
		subscriptions = records.subscriptions
		previous_by_id = {}
		previous.each { |p| previous_by_id[p.id] = p }

	  current.each do |mag|
			new_issue = false
	    # find updated magazines
	    if previous_by_id.has_key? mag.id
				unless mag.has_same_cover?(previous_by_id[mag.id])
					new_issue = true
				end
			else
				# just add it no comparison possible
				new_issue = true
			end
			# that are subscribed to
			if subscriptions.include? mag.id and new_issue
				updates << mag.id
				message += mag.title + ', '
			end
	  end

		records.save_catalogue(previous, true)
		records.save_catalogue(current, false)

		return { :updates => updates, :message => message }
	end

	def self.update(library, records)
		new_issues = get_updated(library, records)
	  errors = checkout_all(library, records, new_issues[:updates])
	  unless errors
			message = new_issues[:message]
	    @@logger.info(message) unless message.empty?
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
		records = Records.instance
		config_file = File.expand_path('config.yaml', File.join(File.dirname(__FILE__), '..'))
		records.load(config_file)
		if records.settings.nil? || records.patrons.nil?
			puts "Configuration file is invalid (missing required sections)"
			return
		end

		@@logger = Logger.instance
		@@logger.file = records.settings['log_file']
		@@logger.level = LogLevel::DEBUG

	  # set up objects
	  library = Library.new(
	    records.settings["landing_page"], records.settings["library_id"])

		# perform actions
		update(library, records) if options[:update]
	  subscriptions(records) if options[:subscriptions]
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
