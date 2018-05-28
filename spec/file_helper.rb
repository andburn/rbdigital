module FileHelper
  def get_data_file(file)
	  File.new(File.join(File.dirname(__FILE__), 'data', file))
	end
end
