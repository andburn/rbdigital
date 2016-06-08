describe 'app' do

		describe 'subscriptions' do

			it 'should print a patrons subscriptions to stdout' do
				record = double(record)
				magazine = instance_double("Magazine",
					:title => "Title", :id => 231, :cover_id => 1783)
				allow(magazine).to receive(:to_s).and_return("Title (231)")
				patron = instance_double("Patron",
					:name => "Name", :email => "Email", :password => "123", :subs => [231])
				allow(record).to receive(:load_catalogue).and_return([magazine])
				allow(record).to receive(:patrons).and_return([patron])
				expect{ App.subscriptions(record) }.to output("\n[Name] ----\nTitle (231)\n").to_stdout
			end

			it 'should print not found if the magazine does not exist' do
				record = double(record)
				patron = instance_double("Patron",
					:name => "Name", :email => "Email", :password => "123", :subs => [1])
				allow(record).to receive(:load_catalogue).and_return([])
				allow(record).to receive(:patrons).and_return([patron])
				expect{ App.subscriptions(record) }.to output("\n[Name] ----\nNot found: 1\n").to_stdout
			end

		end

		describe 'update' do

			it 'should return a list of updated mag ids' do
				record = double(record)
				library = double(library)
				magazine = instance_double("Magazine",
					:title => "Title", :id => 123, :cover_id => 1783)

				allow(record).to receive(:load_catalogue).and_return([magazine])
				allow(record).to receive(:subscriptions).and_return([123])
				allow(record).to receive(:save_catalogue)
				allow(library).to receive(:build_catalogue).and_return([magazine])
				allow(magazine).to receive(:has_same_cover?).and_return(false)

				expect(App.get_updated(library, record)).to eq({
						:updates => [ 123 ],
						:message => 'Title, '
				})
			end

		end

end
