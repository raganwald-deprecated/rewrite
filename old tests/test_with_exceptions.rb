require File.dirname(__FILE__) +  '/test_helper.rb'

include Rewrite::With
include Rewrite::Prelude

class Symbol
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end
end

module Rewrite

  class TestWithExceptions < Test::Unit::TestCase
    
    def test_raise_exception
      assert_raise(RuntimeError) do
        raise "foo"
      end
      assert_raise(RuntimeError) do
        with(andand) do
          raise "foo"
        end
      end
    end
    
    def test_assert_within_with
      assert_raise(Test::Unit::AssertionFailedError) do
        assert_equal(1, 2)
      end
      assert_raise(Test::Unit::AssertionFailedError) do
        with(andand) do
          assert_equal(1, 2)
        end
      end
    end
    
    def test_assert_wrapping_altered_code
      assert_raise(Test::Unit::AssertionFailedError) do
        with(andand) do
          assert_equal(1, 1.andand + 1)
        end
      end
      assert_nothing_raised(Test::Unit::AssertionFailedError) do
        with(andand) do
          assert_equal(2, 1.andand + 1)
        end
      end
    end
    
  end
  
end