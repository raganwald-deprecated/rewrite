require File.dirname(__FILE__) + '/test_helper.rb'

include Rewrite::With
include Rewrite::Prelude
  
class Symbol
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end
end

class TestAndand < Test::Unit::TestCase
  
  def test_simple_andand
    assert_equal(
      'Hello' + ' World', 
      with(andand) do
          'Hello'.andand + ' World'
      end
    )
    assert_nil(
      with(andand) do
          nil.andand + ' World'
      end
    )
  end
  
  def test_with_parameters
=begin
  [:proc, 
    nil, 
    [:call, 
      [:call, [:lit, 1], :andand], 
      :+, 
      [:array, [:lit, 2]]
    ]
  ]
=end
    assert_equal(
      1.+(2),
      with(andand) do
        1.andand.+(2)
      end
    )
    assert_nil(
      with(andand) do
        nil.andand.+(2)
      end
    )
  end
  
  def test_with_a_block
=begin
  [:proc, 
    nil,
    [:iter, 
      [:call, [:call, [:lit, 1..10], :andand], :inject], 
      [:masgn, [:array, [:dasgn_curr, :x], [:dasgn_curr, :y]]], 
      [:call, [:dvar, :x], :+, [:array, [:dvar, :y]]]
    ]
  ]
=end
    assert_equal(
      (1..10).inject { |x, y| x + y },
      with(andand) do
        (1..10).andand.inject { |x, y| x + y }
      end
    )
    assert_nil(
      with(andand) do
        nil.andand.inject { |x, y| x + y }
      end
    )
  end
  
  def test_with_a_parameter_and_a_block
    assert_equal(
      (1..10).inject(42) { |x, y| x + y },
      with(andand) do
        (1..10).andand.inject(42) { |x, y| x + y }
      end
    )
    assert_nil(
      with(andand) do
        nil.andand.inject(42) { |x, y| x + y }
      end
    )
  end
  
  def test_with_a_block_pass
    assert_equal(
      (1..10).inject(42, &:+),
      with(andand) do
        (1..10).andand.inject(42, &:+)
      end
    )
    assert_nil(
      with(andand) do
        nil.andand.inject(42, &:+)
      end
    )
  end
  
  def test_nest
    assert_equal(
      (1..10).inject((1..5).inject(-5) { |x, y| x * y }) { |x, y| x + y },
      with(andand) do
        (1..10).andand.inject(
          (1..5).andand.inject(-5) { |x, y| x * y }
        ) { |x, y| x + y }
      end
    )
    assert_nil(
      with(andand) do
        nil.andand.inject((1..5).andand.inject(-5) { |x, y| x * y }) { |x, y| x + y }
      end
    )
  end
  
end