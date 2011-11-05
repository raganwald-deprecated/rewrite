require File.dirname(__FILE__) + '/test_helper.rb'

class TestCalledByName < Test::Unit::TestCase

  include Rewrite::With
  include Rewrite::Prelude
  
  def test_andand_by_name
    called_by_name(:our_and) { |x,y|
      if temp = x
        y
      else
        temp
      end
    }
  end
  
  def test_nullo_case
    assert_equal(
      Rewrite.arr_for do 
         lambda { |foo| 
           foo.call(lambda { :foo })
         }.call(
          lambda { |x| nil }
         )
      end, 
      called_by_name(:foo) { |x| nil }.process(
        Rewrite.sexp_for do
          foo(:foo)
        end
      ).to_a
    )
  end
  
  def test_regular_rewrite
    assert_equal(
      Rewrite.arr_for do 
         lambda { |foo| 
           foo.call(lambda { 2 }, lambda { 2 })
         }.call(
          lambda { |x, y| x.call + y.call }
         )
      end, 
      called_by_name(:foo) { |x, y| x + y }.process(
        Rewrite.sexp_for do
          foo(2,2)
        end
      ).to_a
    )
  end
  
  def test_splatted_rewrite
    assert_equal(
      Rewrite.arr_for do 
         lambda { |foo| 
           foo.call(Rewrite::CallSplattedByThunk::Parameters.new(lambda { 2 }, lambda { 2 }))
         }.call(
          lambda { |*args| args.inject { |acc, item| acc + item } }
         )
      end, 
      called_by_name(:foo) { |*args| args.inject { |acc, item| acc + item } }.process(
        Rewrite.sexp_for do
          foo(2,2)
        end
      ).to_a
    )
  end
  
  def test_thunk_semantics
    Rewrite.with(
      called_by_name(:foo) { |change_it, get_it| 
        assert_equal(0, get_it)
        change_it # note the interpreter warning here: it thinks we are doing a useless variable reference
        assert_equal(100, get_it)
      }
    ) do
      x = 0
      foo(x = 100, x)
    end
  end
  
  def test_short_circuit_implication
      with(
        called_by_name(:my_or) { |arg1, arg2|
          if arg1
            arg1
          else
            arg2
          end
        }
      ) do
        my_or(
          true, nil.raise_missing_method_exception
        )
      end
  end
  
end