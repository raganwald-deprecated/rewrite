$:.unshift File.dirname(__FILE__)

module Rewrite
  
  module ByExample
    
    # Natches a sequence containing one item. Wraps an entity matcher,
    # with the wrapped matcher matching the one item.
    #
    # Confusing? Consider SymbolEntity.new(:foo). It matches a single
    # entity, :foo. Whereas LengthOne.new(SymbolEntity.new(:foo)) matches
    # a sequence of length one where that one thing happens to match :foo.
    #
    # This distinction is important because sequences can only consist of
    # collections of other sequences. So the LengthOnes are leaves of
    # the sequence trees.
    class LengthOne < Sequence
      
      attr_reader :matcher
      
      def initialize(entity_matcher)
        @matcher = entity_matcher
        @lambda = lambda { |arr| entity_matcher.unfold(arr.first) }
      end
      
      def unfolders_by_length(length)
        if length == 1
          [ @lambda ]
        else
          []
        end
      end
      
      def length_range
        1..1
      end
      
      def to_s
        "<#{matcher.to_s}>"
      end
      
      def fold(enum_of_bindings)
        matcher.fold(enum_of_bindings)
      end
      
    end
    
  end
  
end