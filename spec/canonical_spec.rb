require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

describe "A canonical spec" do
  
  before(:each) do
    @it = true
  end
  
  it "should run an example" do
    @it.should be_true
  end
  
end