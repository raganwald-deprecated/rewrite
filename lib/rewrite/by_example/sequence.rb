$:.unshift File.dirname(__FILE__)

module Rewrite
  
  module ByExample
    
    # Base class fo all classes that match one or more entities within a list.
    #
    # Includes some backtracking magic to handle cases isomorphic to /.*foo/
    class Sequence
      
      # unfolders takes a length and answers a (possible empty) Enumerable of lambdas, 
      # each of which has the method #call(array) and returning an unfold.
      #
      # Now obviously this means that there are three different ways to represent alternation.
      # First, if a sequence matches two things of different lengths, like A | AA, it returns
      # A for unfolders_by_length(1) and AA for unfolders_by_length(2). However, if a sequence
      # matches two things of the same length, tehre are two different ways to represent that.
      #
      # For example, if a sequence matches A | B, it can do either of:
      # 
      # unfolders_by_length(1) =>
      #   [ lambda { |arr| A =~ arr.first }, lambda { |arr| B =~ arr.first } ]
      #
      # or:
      #
      # unfolders_by_length(1) =>
      #   [ lambda { |arr| A =~ arr.first || B =~ arr.first } ]
      #
      # Note the difference: The first example returns two lambdas, one matching A and the
      # other matching B. the second example returns a single lambda matching A or B.
      #
      # When would you use one over the other? The first example is to be used when you wish
      # to support backtracking. The second example is to be used when you do not wish to
      # support backtracking.
      # 
      def unfolders_by_length(length)
        raise 'implemented by subclass'
      end
      remove_method :unfolders_by_length
      
      # Answer a range of possible lengths
      def length_range
        raise 'implemented by subclass'
      end
      remove_method :length_range
      
      def fold(enum_of_bindings)
        raise "Subclass #{self.class} should implement fold"
      end
      remove_method :fold
      
    end
    
  end
  
end