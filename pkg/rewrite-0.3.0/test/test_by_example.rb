require File.dirname(__FILE__) +  '/test_helper.rb'

require 'sexp'

include Rewrite::With

module Rewrite
  
  module ByExample

    class TestByExample < Test::Unit::TestCase
      
      def sexp &proc
        proc.to_sexp[2]
      end
  
      def test_simple_entity_matcher
        foo_andand_bar = nil
        ObjectToMatcher.quietly do
          foo_andand_bar = ObjectToMatcher.from_object( s(:call,
            s(:call,
              s(:vcall, :foo),
              :andand
            ),
            :bar)
          )
        end
        assert_not_nil(foo_andand_bar.unfold(
          s(:call, s(:call, s(:vcall, :foo), :andand), :bar)
        ))
        assert_nil(foo_andand_bar.unfold(
          s(:call, s(:call, s(:vcall, :bar), :andand), :foo)
        ))
      end
          
      def test_simple_bind
        foo_andand_bar = ObjectToMatcher.from_sexp( :call,
          s(:call,
            Bind.new(:receiver, AnyEntity.new),
            :andand
          ),
          Bind.new(:message, AnyEntity.new)
        )
        assert_equal(
          {
            :receiver => s(:vcall, :foo),
            :message => :bar
          },
          foo_andand_bar.unfold(
            s(:call, s(:call, s(:vcall, :foo), :andand), :bar)
          )
        )
      end
      
      def test_any
        any = ObjectToMatcher.from_sexp(
          UnionOfEntitiesSequence.new(:foo, :bar)
        )
        assert_not_nil(any.unfold(
          s(:foo)
        ))
        assert_not_nil(any.unfold(
          s(:bar)
        ))
        assert_nil(any.unfold(
          s(:bash)
        ))
      end
      
      def test_bind_expression_by_example
        something_andand_bar = ObjectToMatcher.binding(/__to_(.*)$/).from_example { __to_something.andand.bar }
        assert_equal(
          { :something => [:vcall, :foo] },
          something_andand_bar.unfold( sexp { foo.andand.bar } )
        )
      end
      
      def test_bind_consistency_by_example
        something_plus_something = ObjectToMatcher.binding(:__to_something).from_example {__to_something + __to_something }
        assert_nil(
          something_plus_something.unfold(sexp { foo + bar })
        )
        assert_nil(
          something_plus_something.unfold(sexp { 1 + 2 })
        )
        assert_not_nil(
          something_plus_something.unfold(sexp { foo + foo })
        )
        assert_not_nil(
          something_plus_something.unfold(sexp { 2 + 2 })
        )
      end
      
      def test_bind_method_name
        foo_andand_something = ObjectToMatcher.binding(/__to_(.*)$/).from_example { foo.andand.__to_something }
        assert_equal(
          { :something => :bar },
          foo_andand_something.unfold( sexp { foo.andand.bar } )
        )
      end
      
      def test_bind_one_parameter
        foo_andand_bar_something = ObjectToMatcher.binding(/__to_(.*)$/).from_example { foo.andand.bar(__to_something) }
        assert_equal(
          { :something => [:lit, :bash] },
          foo_andand_bar_something.unfold( sexp { foo.andand.bar(:bash) } )
        )
      end
      
      def test_bind_sequence
        unfolder = ObjectToMatcher.from_object(s(:array, BindSequence.new(:something)))
        assert_equal(
          { :something => [[:lit, :bash], [:lit, :blitz]] },
          unfolder.unfold(
            s(:array, s(:lit, :bash), s(:lit, :blitz))
          )
        )
      end
      
      def test_bind_parameter_list
        foo_andand_bar_somethings = ObjectToMatcher.binding([/__splat_(.*)$/]).from_example { foo.andand.bar(__splat_something) }
        assert_equal(
          { :something => [[:lit, :bash], [:lit, :blitz]] },
          foo_andand_bar_somethings.unfold( sexp { foo.andand.bar(:bash, :blitz) } )
        )
      end
      
      def test_refolding_entities
        foo_andand_bar_something = ObjectToMatcher.binding(/__to_(.*)$/).from_example { foo.andand.bar(__to_something) }
        assert_equal(
          sexp { foo.andand.bar(:bash) },
          foo_andand_bar_something.fold( { :something => [:lit, :bash] } )
        )
      end
      
      def test_refolding_sequences
        foo_andand_bar_somethings = ObjectToMatcher.binding([/__splat_(.*)$/]).from_example { foo.andand.bar(__splat_something) }
        assert_equal(
          sexp { foo.andand.bar(:bash, :blitz) },
          foo_andand_bar_somethings.fold( { :something => [[:lit, :bash], [:lit, :blitz]] } )
        )
      end
      
      def test_simple_andand_refold
        folder = ObjectToMatcher.binding(/^__to_(.*)$/).from_example {
          lambda { |__G12345__|
            __G12345__ && __G12345__.__to_message
          }.call(__to_receiver)
        }
        assert_equal(
          sexp {
            lambda { |__G12345__|
              __G12345__ && __G12345__.age
            }.call(Person.find_by_name('Otto'))
          },
          folder.fold( :receiver => sexp { Person.find_by_name('Otto') }, :message => :age )
        )
      end
      
      def test_simple_andand_hylomorphism
        unfolder = ObjectToMatcher.binding(/^__to_(.*)$/).from_example {
          __to_receiver.andand.__to_message
        }
        folder = ObjectToMatcher.binding(/^__to_(.*)$/).from_example {
          lambda { |__G12345__|
            __G12345__ && __G12345__.__to_message
          }.call(__to_receiver)
        }
        assert_equal(
          sexp {
            lambda { |__G12345__|
              __G12345__ && __G12345__.age
            }.call(Person.find_by_name('Otto'))
          },
          begin
            unfolded = unfolder.unfold(
              sexp { Person.find_by_name('Otto').andand.age }
            )
            folder.fold(unfolded)
          end
        )
      end
      
      def test_andand_hylomorphism_with_a_parameter
        unfolder = ObjectToMatcher.binding(/^__to_(.*)$/).from_example {
          __to_receiver.andand.__to_message(__to_parameter)
        }
        folder = ObjectToMatcher.binding(/^__to_(.*)$/).from_example {
          lambda { |__G12345__|
            __G12345__ && __G12345__.__to_message(__to_parameter)
          }.call(__to_receiver)
        }
        assert_equal(
          sexp {
            lambda { |__G12345__|
              __G12345__ && __G12345__.age(true)
            }.call(Person.find_by_name('Otto'))
          },
          folder.fold(
            unfolder.unfold(
              sexp { Person.find_by_name('Otto').andand.age(true) }
            )
          )
        )
      end
      
      def test_alternate_folder
        folder = ObjectToMatcher.binding(/^__to_(.*)$/).from_example {
          lambda { |__G12345__|
            __G12345__.__to_message unless __G12345__.nil?
          }.call(__to_receiver)
        }
        assert_not_nil(
          folder.fold(
            :receiver => s(:vcall, :foo),
            :message => :bar
          )
        )
      end
      
      def test_andand_hylomorphism_with_a_parameter_list
        unfolder = ObjectToMatcher.binding(/^__to_(.*)$/, [/^__splat_(.*)$/]).from_example {
          __to_receiver.andand.__to_message(__splat_parameters)
        }
        subject = sexp { Person.andand.find(1,2,3) }
        unfolded = unfolder.unfold(subject)
        folder = ObjectToMatcher.binding(/^__to_(.*)$/, [/^__splat_(.*)$/]).from_example {
          lambda { |__G12345__|
            __G12345__ && __G12345__.__to_message(__splat_parameters)
          }.call(__to_receiver)
        }
        assert_equal(
          sexp {
            lambda { |__G12345__|
              __G12345__ && __G12345__.find(1,2,3)
            }.call(Person)
          },
          folder.fold(
            unfolded
          )
        )
      end
      
      def test_alternate_andand_hylomorphism_with_a_parameter_list
        unfolder = ObjectToMatcher.binding(:receiver, :message, [:params]).from_example {
          receiver.andand.message(params)
        }
        folder = ObjectToMatcher.binding(:receiver, :message, [:params]).from_example {
          lambda { |__G12345__|
            __G12345__.message(params) unless __G12345__.nil?
          }.call(receiver)
        }
        assert_equal(
          sexp {
            lambda { |__G12345__|
              __G12345__.find(1,2,3) unless __G12345__.nil?
            }.call(Person)
          },
          folder.fold(
            unfolder.unfold(
              sexp { Person.andand.find(1,2,3) }
            )
          )
        )
      end
      
      # TODO: * Processor class with a nice syntax ('literate'?)
      # TODO: * Hygienic, implemented as dogfood. How the freak would that work?
      
      def test_unhygienic_andand
        andand = Unhygienic.
        from(:receiver, :message, [:parameters]) {
          receiver.andand.message(parameters)
        }.
        to {
          lambda { |andand_temp|
            andand_temp.message(parameters) if andand_temp
          }.call(receiver)
        }
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
      
      def test_literal_symbol
        litsym = LiteralEntity.new
        assert_not_nil(
          litsym.unfold(s(:lit, :foo))
        )
        assert_not_nil(
          litsym.unfold(sexp { :foo })
        )
        assert_nil(
          litsym.unfold(sexp { 'bar' })
        )
        assert_nil(
          litsym.unfold(sexp { 'bas'.to_sym })
        )
      end
      
      def test_symbol_to_proc
        
      end
  
    end

  end

end