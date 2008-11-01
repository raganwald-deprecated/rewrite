$:.unshift File.dirname(__FILE__)

require File.expand_path(File.dirname(__FILE__) +'/sequence.rb')

module Rewrite
  
  module ByExample
    
    # Matches any sequence of zero or more entities and binds the list
    # to a name in the unfolded result. BindSequence.new('name') binds
    # whatever sequence of entities it matches to 'name'.
    #
    # Not isomorphic to AnyEntity: AnyEntity matches one entity,
    # BindSequence matches a sequence of entities. If you want to match
    # a single entity that happens to consist
    #
    #   LengthOne.new(Bind.new('name), AnyEntity.new)
    class BindSequence < Sequence
      attr_reader :unfolder_lambda, :name
      
      def initialize(name)
        @name = name.to_sym
        @unfolder_lambda = lambda { |arr| { @name => s(*arr) } }
      end
      
      def unfolders_by_length(length)
        [ unfolder_lambda ]
      end
      
      def length_range
        0..10000
      end
      
      def fold(enum_of_bindings)
        enum_of_bindings[name]
      end
      
      def to_s
        "__* => #{name.inspect}"
      end
      
    end
    
  end
  
end