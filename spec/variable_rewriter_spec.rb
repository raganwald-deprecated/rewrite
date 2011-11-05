require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

describe Rewrite::VariableRewriter do
  
  describe "The target expression" do
    
    before(:each) do
      @it = proc { |a| lambda { |b| b } }.to_sexp
    end
    
    it "should help me understand the new representation" do
      @it.to_a.should == [:iter, [:call, nil, :proc, [:arglist]], [:lasgn, :a], [:iter, [:call, nil, :lambda, [:arglist]], [:lasgn, :b], [:lvar, :b]]]
    end
    
    it "should string out back to what we expect" do
      Ruby2Ruby.new.process(lambda { |a| lambda { |b| b } }.to_sexp).should == 'proc { |a| lambda { |b| b } }'
    end
    
  end
  
  describe "The simplest possible variable expression" do
    
    before(:each) do
      @identity = proc { |a| a }.to_sexp
    end
    
    it "should have the new representation" do
      @identity.to_a.should == [:iter, 
        [:call, nil, :proc, [:arglist]],
        [:lasgn, :a],
        [:lvar, :a]
      ]
    end
    
    describe "A VariableRewriter" do
      
      before(:each) do
        @rewriter = Rewrite::VariableRewriter.new(:a, s(:lit, 42))
      end

      describe "having processed our identity proc" do

        before(:each) do
          @it = @rewriter.process(proc { |a| a }.to_sexp)
        end

        it "should not make any changes because :a has been shadowed" do
          @it.to_a.should == proc { |a| a }.to_sexp.to_a
        end

      end

      describe "having processed a function call" do

        before(:each) do
          @it = @rewriter.process( proc { |b| a }.to_sexp ) # not a variable because it is not in scope, equivalent to a()
        end

        it "should not make any changes because :a is not a variable lookup" do
          @it.to_a.should == proc { |b| a }.to_sexp.to_a
        end

      end

      describe "having processed a variable reference" do

        before(:each) do
          a = nil
          @it = @rewriter.process( proc { |b| a }.to_sexp ) # a is closed over
        end

        it "should should change a to a literal" do
          @it.to_a.should == proc { |b| 42 }.to_sexp.to_a
        end

      end
      
      describe "having processed a nested expression" do
        
        before(:each) do
          a = nil
          @it = @rewriter.process(
            proc do
              p a
              proc do |a|
                p a
              end
            end.to_sexp
          )
        end
        
        it "should convert the first but not the second" do
          @it.to_a.should == proc do
            p 42
            proc do |a|
              p a
            end
          end.to_sexp.to_a
        end
        
      end
      
    end
    
  end
  
end