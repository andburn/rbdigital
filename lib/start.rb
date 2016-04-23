require 'optparse'

require_relative 'library'
require_relative 'patron'
require_relative 'storage'
require_relative 'utils'
require_relative 'app'

# load config
# App::Config.load("config.yaml")
# logger = App::Logger.new

def checkout_all(library, storage, list)
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

def subscribe(patron)
  patron = storage.get_patron(patron)
  current = library.build_catalogue
  dead = []
  current.each_with_index do |m, i|
    back_issues_only = library.archived?(m.id)
    subs = storage.get_subscription(m.id)
    prefix = ' '
    if subs =~ /#{patron.user_name}/
      prefix = '*'
    end
    if back_issues_only
      dead << sprintf("[%02d]%s %s\n", i, prefix, m.title)
    else
      printf("[%02d]%s %s\n", i, prefix, m.title)
    end
  end
  if !dead.empty?
    puts "\n---- Back Issues Only ----"
    dead.each {|d| puts d}
    puts "\n--------------------------\n"
  end
  puts 'Enter selection:'
  selection = gets.chomp.split(/,/)
  selection.each do |i|
    unless i =~ /\d+/
      puts "Index '#{i}' not a number, skipping."
      next
    end
    index = i.to_i
    if index >= current.length || index < 0
      puts "Unknown index #{index}, skipping."
      next
    end
    mag = current[index]
    storage.add_subscription(mag.id, mag.title, patron.user_name)
  end
end

def catalogue()
  previous = storage.load_catalogue
  current = library.build_catalogue
  log('Magazine selection changed!') if previous.length != current.length
end

def update()
  # get list of subscribed items

  # check individual pages for update

  # checkout new

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

def main()
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: start.rb [options]'
    # update is the default
    opts.on('-u', '--update') { options[:update] = true }
    # add progress info to output
    opts.on('-v', '--verbose') { options[:verbose] = true }
    # overrides update (even if '-u' specified)
    opts.on('-s', '--subscribe') { options[:subscribe] = true }
    # to be used with subscribe
    opts.on('-p', '--patron NAME') do |v|
      options[:patron] = v
    end
  end.parse!

  # set up objects
  library = App::Library.new(
    App::Config.settings["landing_page"], App::Config.settings["library_id"])
  storage = App::Storage.new


  if options[:subscribe] && options[:patron]
    subscribe(options[:patron])
  elsif options[:update]
    update()
  end
end


if __FILE__ == $0
    main()
end
