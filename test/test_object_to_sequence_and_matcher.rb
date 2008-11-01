require File.dirname(__FILE__) +  '/test_helper.rb'

require 'sexp'

module Rewrite
  
  module ByExample

    class TestObjectToPattern < Test::Unit::TestCase

      include Rewrite::With
      
      def sexp &proc
        proc.to_sexp[2]
      end
      
      def test_object_matcher_proc_capturer_integrity
        assert_nothing_raised(Exception) do
          ObjectToMatcher.proc_capturer
        end
      end
      
      def test_symbol_like_expression_matcher_integrity
        assert_equal(
          "s( (<:gvar> | <:dvar> | <:vcall> | <:lcall> | <:lit>), <__ => :variable_symbol> )",
          ObjectToMatcher.symbol_like_expression_matcher.to_s
        )
      end
      
      def test_object_to_pattern
        assert_equal(/^(foo)$/, ObjectToMatcher.object_to_pattern(:foo))
        assert_equal(/^(foo)$/, ObjectToMatcher.object_to_pattern('foo'))
      end
      
      def test_internal_binder
        o2m = ObjectToMatcher.binding(:foo)
        result = nil
        ObjectToMatcher.quietly do
          result = o2m.from_object(
            s(:vcall, :foo)
          )
        end
        assert_equal("__ => :foo", result.to_s)
      end
      
      def test_splatter
        result = nil
        ObjectToMatcher.quietly do
          result = ObjectToMatcher.binding([:splat]).from_object(
              s(
                :array,
                s(:vcall, :splat)
              )
            )
        end
        assert_equal("s( <:array>, __* => :splat )", result.to_s)
      end
      
      def test_binder_at_top_level
        assert_equal(
          ObjectToMatcher.binding('foo', :bar).from_object(
            s(:vcall, :foo)
          ).to_s, 
          ObjectToMatcher.binding('foo', :bar).from_example { foo }.to_s
        )
        assert_equal(
          "__ => :foo", 
          ObjectToMatcher.binding('foo', :bar).from_object(
            s(:vcall, :foo)
          ).to_s
        )
        assert_equal(
          "__ => :foo", 
          ObjectToMatcher.binding('foo', :bar).from_example { foo }.to_s
        )
        assert_equal(
          "s( <:call>, <__ => :foo>, <__ => :bar> )",
          ObjectToMatcher.binding('foo', :bar).from_example { foo.bar }.to_s
        )
      end
      
      def test_proc_extraction
        entity = ObjectToMatcher.from_object([:proc, nil,  Bind.new(:sexp, AnyEntity.new)])
        assert_equal("s( <:proc>, <nil>, <__ => :sexp> )", entity.to_s)
      end
      
      def test_proc_to_sexp
        entity = ObjectToMatcher.from_example { a }
        assert_equal("s( <:vcall>, <:a> )", entity.to_s)
      end
      
      def test_unfold_simplest
        unfolder = ObjectToMatcher.binding('foo', :bar).from_example { foo }
        assert_not_nil(unfolder.unfold(sexp { a }), "top-level expression is not a match")
      end
      
      def test_method_call
        unfolder = ObjectToMatcher.binding('foo', :bar).from_example { foo.bar }
        assert_not_nil(unfolder.unfold(sexp { a.b }))
      end
      
      def test_unfolding_and_refolding
        unfolder = ObjectToMatcher.binding(/^__to_(.*)$/).from_example {
          __to_receiver.andand.__to_message
        }
        subject = sexp { foo.andand.bar }
        unfolded = unfolder.unfold(subject)
        assert_equal(
          {:message=>:bar, :receiver=>[:vcall, :foo]}, 
          unfolded
        )
        refolder = ObjectToMatcher.binding(/^__to_(.*)$/).from_example {
          lambda { |andand_helper|
            andand_helper.__to_message if andand_helper
          }.call(__to_receiver)
        }
        rewritten = eval(refolder.fold(unfolded).to_s)
        assert_equal(
          "lambda { |andand_helper| andand_helper.bar if andand_helper }.call(foo)", 
          Ruby2Ruby.new.process(rewritten)
        )
      end
      
    end
    
  end
  
end