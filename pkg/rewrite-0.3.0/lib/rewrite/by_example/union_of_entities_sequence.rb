$:.unshift File.dirname(__FILE__)

require File.expand_path(File.dirname(__FILE__) +'/sequence.rb')

module Rewrite
  
  module ByExample
    
    #--
    #
    # Acts like a union of sequences but is initialized with entities. Could be better!
    class UnionOfEntitiesSequence < Sequence
      
      attr_accessor :matchers, :length_range
      
      def initialize(*matchers)
        self.matchers = matchers.map { |matcher| 
          LengthOne.new(ObjectToMatcher.from_object(matcher))
        }
        @length_range = @matchers.inject(0..0) { |range, matcher| range_union(range, matcher.length_range) }
      end
      
      def unfolders_by_length(length)
        self.matchers.inject([]) { |unfolders, matcher| unfolders + matcher.unfolders_by_length(length) }
      end
      
      def range_union(range1, range2)
        ([range1.begin, range2.begin].min)..([range1.end, range2.end].max)
      end
      
      def to_s
        "(#{matchers.map { |m| m.to_s }.join(' | ')})"
      end
      
    end
    
  end
  
end