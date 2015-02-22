require 'rspec'

require_relative '../lib/library'
require_relative '../lib/patron'
require_relative '../lib/storage'

describe 'logged_in?' do

  before(:all) do
    @spec_dir = File.dirname(__FILE__)
  end

  it 'should be logged out' do
    site = Library.new(File.join(@spec_dir, 'data', 'logged_out.html'))
    expect(site.logged_in?).to be_falsey
  end

  it 'should be logged in' do
    site = Library.new(File.join(@spec_dir, 'data', 'logged_in.html'))
    expect(site.logged_in?).to be_truthy
  end

  it 'should be false for unknown' do
    site = Library.new(File.join(@spec_dir, 'data', 'wrong_page.html'))
    expect(site.logged_in?).to be_falsey
  end

end

describe 'log_in' do

  before(:each) do
    store = Storage.new
    @patron = store.get_patron('axle')
    @library = Library.new('http://www.rbdigital.com/southdublin/service/zinio/landing/')
  end

  it 'should log in from logged out state' do
    @library.log_out
    expect(@library.logged_in?).to be_falsey
    @library.log_in(@patron)
    expect(@library.logged_in?).to be_truthy
  end

end

describe 'build_catalogue' do

  before(:each) do
    store = Storage.new
    @patron = store.get_patron('axle')
    @library = Library.new('http://www.rbdigital.com/southdublin/service/zinio/landing/')
    @spec_dir = File.dirname(__FILE__)
  end

  it 'should get the correct number of pages available' do
    catalogue = @library.build_catalogue_page(
      File.join(@spec_dir, 'data', 'catalogue_small_new.html'), 1, true)
    expect(catalogue.pop).to eq(7)
  end

  # TODO: adjust this so takes account of multi page
  it 'should create a list of all available magazines' do
    catalogue = @library.build_catalogue(File.join(@spec_dir, 'data', 'catalogue_small.html'))
    expect(catalogue.length).to eq(4)
  end

  it 'should handle an error in getting catalogue' do
    catalogue = @library.build_catalogue(File.join(@spec_dir, 'data', 'catalogue_error.html'))
    expect(catalogue.length).to eq(0)
  end

end
