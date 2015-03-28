require 'optparse'
#require 'ruby_gntp'

require_relative 'library'
require_relative 'patron'
require_relative 'storage'

LOG_FILE = File.expand_path('data/log.txt', File.join(File.dirname(__FILE__), '..'))
START_PAGE = 'http://www.rbdigital.com/southdublin/service/zinio/landing/'

def log(message)
  File.open(LOG_FILE, 'a+') do |f|
    f.write(Time.now.strftime('[%Y-%m-%d %H:%M:%S] ') + message + "\n")
  end
end

def growl(message)
  # icon_url = '<project_dir>/images/zinio_icon.png'
  #
  # GNTP.notify({
  #                 :app_name => 'Zinio Update',
  #                 :title    => 'New issues found',
  #                 :text     => message,
  #                 :icon     => icon_url
  #             })
  log(message)
end

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
    errors = true unless library.logged_in?
    if not library.logged_in?
      errors = true
      log 'login error for ' + patron.user_name
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


log("Script starting...")
# NOTE: alternative to optparse http://docopt.org/
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: start.rb [options]'

  opts.on('-s', '--subscribe') { options[:subscribe] = true }
  opts.on('-u', '--update') { options[:update] = true }

  opts.on('-p', '--patron NAME') do |v|
    options[:patron] = v
  end
end.parse!

# set up objects
library = Library.new(START_PAGE)
storage = Storage.new

# subscribe takes precedence over update (should be mutually exclusive)
if options[:subscribe] && !options[:patron].empty?
  patron = storage.get_patron(options[:patron])
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
elsif options[:update]
  previous = storage.load_catalogue
  current = library.build_catalogue
  growl('Magazine selection changed!') if previous.length != current.length
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
    growl(message) unless message.empty?
    storage.save_catalogue(current)
  end
end
log("...finished.")
