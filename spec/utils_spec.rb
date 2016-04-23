describe "Logger" do

	before(:all) do
		@logger = App::Logger.new
	end

	it "should write message to file" do
		buffer = StringIO.new
		allow(File).to receive(:open).with(@logger.file,'a+').and_yield(buffer)
		@logger.log("some message")
		expect(buffer.string).to match(/some message/)
	end

	it "should have an alias for debug" do
		expect(@logger).to receive(:log).with('debugging', App::LogLevel::DEBUG)
		@logger.debug('debugging')
	end

	it "should have an alias for info" do
		expect(@logger).to receive(:log).with('infos', App::LogLevel::INFO)
		@logger.info('infos')
	end

	it "should have an alias for error" do
		expect(@logger).to receive(:log).with('errors', App::LogLevel::ERROR)
		@logger.error('errors')
	end

end
