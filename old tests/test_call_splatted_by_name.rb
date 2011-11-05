require File.dirname(__FILE__) + '/test_helper.rb'
require 'rubygems'
require 'parse_tree'
require 'sexp_processor'

module Rewrite

  class TestWith < Test::Unit::TestCase
  
    include Rewrite::With
    include Rewrite::Prelude
  
    def test_rewrite_splatted
      assert_equal(
        lambda { |foo|
            Rewrite.arr_for { 
            foo.call(Rewrite::CallSplattedByThunk::Parameters.new(lambda { :bar }))
          }
        }.call(nil), 
        CallSplattedByThunk.new(:foo).process(
          Rewrite.sexp_for { foo(:bar) }
        ).to_a
      )
    end
    
    def raise_this(ex)
      raise ex
    end
    
    def test_rewrite_splatted_semantics
      with(
        called_by_name(:try_these) { |*clauses|
          clauses.each { |clause| return clause rescue nil }
          nil
        }
      ) do
        assert_nothing_raised(Exception) do
          try_these(raise_this("foo"), raise_this("bar"), :foo)
        end
      end
    end
  
  end

end