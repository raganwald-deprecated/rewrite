require File.dirname(__FILE__) + '/test_helper.rb'

module Rewrite

  class TestCallByThunk < Test::Unit::TestCase
    
    def test_nothings
      assert_equal(
        Rewrite.arr_for do 
           :baz
        end, 
        CallByThunk.new().process(
          Rewrite.sexp_for do
            :baz
          end
        ).to_a
      )
      assert_equal(
        Rewrite.arr_for do 
           :baz
        end, 
        CallByThunk.new(:foo).process(
          Rewrite.sexp_for do
            :baz
          end
        ).to_a
      )
      assert_equal(
        Rewrite.arr_for do 
           bar(:baz)
        end, 
        CallByThunk.new(:foo).process(
          Rewrite.sexp_for do
            bar(:baz)
          end
        ).to_a
      )
    end
    
    def test_convert_one_empty
      assert_equal(
        lambda { |foo|
          Rewrite.arr_for do 
             foo.call()
          end
        }.call(nil), 
        CallByThunk.new(:foo).process(
          Rewrite.sexp_for do
            foo()
          end
        ).to_a
      )
    end
    
    def test_convert_one
      assert_equal(
        lambda { |foo| # make foo a dvar
          Rewrite.arr_for do 
             foo.call(lambda { :baz })
          end
        }.call(nil), 
        CallByThunk.new(:foo).process(
          Rewrite.sexp_for do
            foo(:baz)
          end
        ).to_a
      )
    end
    
    def test_nested_invocation
      assert_equal(
        lambda { |fib|
          Rewrite.arr_for do 
             fib.call(lambda { fib.call(lambda { n-1 }) })
          end
        }.call(nil), 
        CallByThunk.new(:fib).process(
          Rewrite.sexp_for do
            fib(fib(n-1))
          end
        ).to_a
      )
    end
    
    def test_nested_but_not_us
      assert_equal(
        lambda { |fib|
          Rewrite.arr_for do 
            foo(
              fib.call(lambda { n-1 })
            )
          end
        }.call(nil), 
        CallByThunk.new(:fib).process(
          Rewrite.sexp_for do
            foo(
              fib(n-1)
            )
          end
        ).to_a
      )
    end
    
  end
  
end