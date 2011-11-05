require File.dirname(__FILE__) + '/test_helper.rb'

module Rewrite

  class TestDefVar < Test::Unit::TestCase
    
    def arr_for &proc
      Rewrite.sexp_for(&proc).to_a
    end
    
    def test_and_one
      assert_equal(
        arr_for { 
          lambda { |foo| :baz }.call(:foo) 
        }, 
        DefVar.new(:foo, Rewrite.sexp_for { :foo }).process(
          Rewrite.sexp_for { :baz }
        ).to_a
      )
    end
    
    def test_one_and_one
      assert_equal(
        arr_for { 
          lambda { |foo, bar| :baz }.call(:foo, :bar) 
        }, 
        DefVar.new(:bar, Rewrite.sexp_for { :bar }).process(
          Rewrite.sexp_for { lambda { |foo| :baz }.call(:foo) }
        ).to_a
      )
    end
    
    def test_two_and_one
      assert_equal(
        arr_for { 
          lambda { |foo, bar, blitz| :baz }.call(:foo, :bar, :blitz) 
        }, 
        DefVar.new(:blitz, Rewrite.sexp_for { :blitz }).process(
          Rewrite.sexp_for { lambda { |foo, bar| :baz }.call(:foo, :bar)  }
        ).to_a
      )
    end

  end

  end