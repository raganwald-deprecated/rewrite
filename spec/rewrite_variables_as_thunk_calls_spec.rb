require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

describe Rewrite::RewriteVariablesAsThunkCalls do
  
  before(:each) do
    @rewriter = Rewrite::RewriteVariablesAsThunkCalls.new(:a)
  end
  
  describe "an irrelevant lambda" do
    
    before(:each) do
      @it = proc { |b| b }
    end
    
    it "should not be changed" do
      @rewriter.process(@it.to_sexp).to_a.should == proc { |b| b }.to_sexp.to_a
    end
    
  end

  describe "the simplest shadow" do

    before(:each) do
      @it = proc { |a| a }
    end

    it "should not be changed" do
      @rewriter.process(@it.to_sexp).to_a.should == proc { |a| a }.to_sexp.to_a
    end

  end

  describe "the simplest closure" do

    before(:each) do
      a = nil
      @it = proc { a }
    end

    it "should be changed" do
      a = nil
      @rewriter.process(@it.to_sexp).to_a.should == proc { a.call }.to_sexp.to_a
    end

  end

    describe "sexp_for" do

      before(:each) do
        a = nil
        @it = Rewrite.sexp_for { a }
      end

      it "should be changed" do
        a = nil
        @rewriter.process(@it).to_a.should == (Rewrite.sexp_for { a.call }).to_a
      end

    end
  
end