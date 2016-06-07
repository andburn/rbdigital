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

		it 'should be able to get setttings hash' do
			allow(YAML).to receive(:load_file).and_return({
	      "settings" => { "library_id" => 2389 }
	    })
			records = App::Records.instance
			records.load("file.txt")
			expect(records.settings['library_id']).to eq(2389)
		end

		it 'should be able to get all patrons' do
			allow(YAML).to receive(:load_file).and_return({
	      "patrons" => [
					{"first" => { "email" => "person1", "password" => "1", "subscriptions" => [1, 2, 3] }},
					{"second" => { "email" => "person2", "password" => "2", "subscriptions" => [1, 2, 5, 6] }}
				]
	    })
			records = App::Records.instance
			records.load("file.txt")
			expect(records.patrons.length).to eq 2
			expect(records.patrons[0].name).to eq("first")
		end

		it 'should get patron from config' do
	    allow(YAML).to receive(:load_file).and_return({
	      "patrons" => {"Bill" => { "email" => "bill@email.com", "password" => "Xzy00", "subscriptions" => [ 1, 2 ] }}
	    })
	    bill = instance_double("Patron", :name => "Bill", :email => "bill@email.com",
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

		it 'should load log_file path' do
			allow(YAML).to receive(:load_file).and_return({
	      "settings" => { "log_file" => "log.txt" }
	    })
			records = App::Records.instance
			records.load("file.txt")
			expect(records.log_file).to match(/log\.txt$/)
		end

	end

	describe 'subscriptions' do

		it 'should merge all patrons subscriptions together without duplicates' do
			allow(YAML).to receive(:load_file).and_return({
				"patrons" => [
					{"a" => { "subscriptions" => [ 1, 2, 3 ] }},
					{"b" => { "subscriptions" => [ 2, 3 ] }},
					{"c" => { "subscriptions" => [ 1, 6, 2 ] }}
				]
			})
			records = App::Records.instance
			records.load("file.txt")
			expect(records.subscriptions.sort).to eq([1, 2, 3, 6])
		end

	end

	describe 'catalogue' do

		it 'should save list to file' do
			buffer = StringIO.new
			allow(File).to receive(:open).and_yield(buffer)
	    list = [
				instance_double("Magazine", :id => 123, :title => 'one', :cover_id => 38348),
				instance_double("Magazine", :id => 321, :title => 'two', :cover_id => 548976),
			]
			App::Records.instance.save_catalogue(list)
			expect(buffer.string).to match(/123;one;38348\n321;two;548976/)
		end

	end

end
