require_relative 'patron'
require_relative 'magazine'

class Storage

  def initialize
    @store_dir = File.expand_path('data', File.join(File.dirname(__FILE__), '..'))
    @patron_file = File.join(@store_dir, 'patrons.txt')
    @subscription_file = File.join(@store_dir, 'subscriptions.txt')
    @catalogue_file = File.join(@store_dir, 'catalogue.txt')
  end

  def add_patron(name, email, password)
    write_to_file(@patron_file, "#{name};#{email};#{password}\n")
  end

  def get_patron(name)
    patrons = load_file_to_array(@patron_file)
    return nil if patrons.nil?
    patrons.each do |p|
      p.chomp!
      if p =~ /^#{name};/
        detail = p.split(/;/)
        next if detail.length != 3
        return Patron.new(detail[0], detail[1], detail[2])
      end
    end
    # return
    nil
  end

  def add_subscription(id, title, user_name)
    current = get_subscription(id)
    if current.nil?
      write_to_file(@subscription_file, "#{id},#{title},#{user_name}\n")
    else
      detail = current.split(/,/)
      return nil if detail.length != 3
      unless detail[2] =~ /#{user_name}/i
        modify_line_in_file(@subscription_file, current,
          "#{current}:#{user_name}")
      end
    end
  end

  def get_subscription(id)
    subs = load_file_to_array(@subscription_file)
    return nil if subs.nil?
    subs.each do |s|
      s.chomp!
      return s if s =~ /^#{id},/
    end
    # return
    nil
  end

  def save_catalogue(catalogue)
    output = ''
    catalogue.each do |mag|
      output += "#{mag.id},#{mag.title},#{mag.cover_url},#{mag.issue_hash}\n"
    end
    unless output.empty?
      #File.delete(@catalogue_file)
      write_to_file(@catalogue_file, output, false)
    end
  end

  def load_catalogue
    magazines = []
    catalogue = load_file_to_array(@catalogue_file)
    catalogue.each do |c|
      m = c.split(/,/)
      next unless m.length == 4
      magazines << Magazine.new(m[1], m[0], m[2])
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
      return nil unless File.exists?(filename)
      File.open(filename, 'r').readlines
    end

    def modify_line_in_file(filename, old, new)
      return nil unless File.exists?(filename)
      lines = File.open(filename, 'r').readlines
      lines.each_with_index do |line, i|
        if line =~ /^#{old}/
          lines[i] = new + "\n"
        end
      end
      File.open(filename, 'w+') do |f|
        lines.each do |line|
          f.write(line)
        end
      end
    end

end