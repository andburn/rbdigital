describe "Logger" do

	before(:all) do
		@logger = App::Logger.instance
	end

	before(:each) do
		@logger.level = App::LogLevel::DEBUG
	end

	describe 'as a sinlgeton' do

		it 'should not have an accessible new method' do
			expect{ App::Logger.new }.to raise_error(NoMethodError)
		end

		it 'should return the same object from instance method' do
			expect(App::Logger.instance).to be(App::Logger.instance)
		end

	end

	it "should have mutatable loglevel attribute" do
		@logger.level = App::LogLevel::ERROR
		expect(@logger.level).to eq App::LogLevel::ERROR
		@logger.level = App::LogLevel::INFO
		expect(@logger.level).to eq App::LogLevel::INFO
	end

	it "should have mutatable file attribute" do
		@logger.file = 'one'
		expect(@logger.file).to eq 'one'
		@logger.file = 'two'
		expect(@logger.file).to eq 'two'
	end

	it "should write message to file" do
		buffer = StringIO.new
		allow(File).to receive(:open).and_yield(buffer)
		allow(File).to receive(:exist?).and_return true
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
