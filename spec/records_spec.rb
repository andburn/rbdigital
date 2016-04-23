describe 'records' do

	describe 'as a sinlgeton' do

		it 'should not have an accessible new method' do
			expect{ App::Records.new }.to raise_error(NoMethodError)
		end

		it 'should return the same object from instance method' do
			expect(App::Records.instance).to be(App::Records.instance)
		end

	end

	describe 'config' do

		it 'should get patron from config' do
	    allow(YAML).to receive(:load_file).and_return({
	      "patrons" => {"Bill" => { "email" => "bill@email.com", "password" => "Xzy00", "subscriptions" => [ 1, 2 ] }}
	    })
	    bill = instance_double("Patron", :user_name => "Bill", :email => "bill@email.com",
				:password => "Xzy00", :subscriptions => [1, 2])
			records = App::Records.instance
			records.load("file.txt")
	    expect(records.get_patron("Bill")).to eq(bill)
	  end

	  it 'should return nil if patron not found' do
			allow(YAML).to receive(:load_file).and_return({ "patrons" => {} })
			records = App::Records.instance
			records.load("file.txt")
	    expect(records.get_patron("Bill")).to be_nil
	  end

		it 'should load catalogue_file path' do
			allow(YAML).to receive(:load_file).and_return({
	      "settings" => { "catalogue_file" => "catalogue.txt" }
	    })
			records = App::Records.instance
			records.load("file.txt")
			expect(records.catalogue_file).to match(/catalogue\.txt$/)
		end

		it 'should save config back to a file' do
			buffer = StringIO.new
			allow(YAML).to receive(:load_file).and_return({ "settings" => { "a" => "b"} })
			allow(File).to receive(:open).with('config.txt','w').and_yield(buffer)

			records = App::Records.instance
			records.load("config.txt")
			records.save("config.txt")
			expect(buffer.string).to eq("---\nsettings:\n  a: b\n")
		end

	end

end
