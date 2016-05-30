describe 'app' do

  # before(:all) do
  #   @config_one = File.join(File.dirname(__FILE__), "data/config_one.yaml")
  #   @config_two = File.join(File.dirname(__FILE__), "data/config_two.yaml")
  # end
  #
  # before(:each) do
  #   App::Config.clear
  # end
  #
  # it 'should load settings from config file' do
	# 	App::Config.load(@config_one)
	# 	expect(App::Config.settings).to eq({ "color" => "green" })
  # end
  #
	# it 'should load patrons from config file' do
	# 	App::Config.load(@config_one)
	# 	expect(App::Config.patrons).to eq({
	# 		"John" => { "email" => "john@email.com", "password" => "Abc123" },
	# 		"Bill" => { "email" => "bill@email.com", "password" => "Xzy00" }
	# 	})
  # end
  #
	# it 'should only load the config file once' do
  #   App::Config.load(@config_one)
	# 	App::Config.load(@config_two)
	# 	expect(App::Config.settings).to eq({ "color" => "green" })
	# end

end
