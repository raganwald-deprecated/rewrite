require File.dirname(__FILE__) + '/test_helper.rb'
require 'rubygems'
require 'parse_tree'
require 'sexp_processor'

class TestWith < Test::Unit::TestCase
  
  include Rewrite::With
  
  class NoopProcessor < SexpProcessor
    
  end
  
  def test_null_processor
    assert_equal(
      :foo, 
      with(NoopProcessor.new) do
          :foo
      end
    )
  end
  
end