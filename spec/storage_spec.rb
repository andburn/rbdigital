require 'rspec'

require_relative '../lib/storage'
require_relative 'spec_helper'

describe 'storage' do

  before(:each) do
    @storage = Storage.new
    @store_dir = File.expand_path('data', File.join(File.dirname(__FILE__), '..'))
  end

  it 'should call write_to_file' do
    expect(@storage).to receive(:write_to_file).with(
        File.join(@store_dir, 'patrons.txt'), "bill;b@mail.com;2222\n")
    @storage.add_patron('bill','b@mail.com','2222')
  end

  it 'should get patron from file' do
    expect(@storage).to receive(:load_file_to_array).with(
      File.join(@store_dir, 'patrons.txt'))
    @storage.get_patron('bill')
  end

end
