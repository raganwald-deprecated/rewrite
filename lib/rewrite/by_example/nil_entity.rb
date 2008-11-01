$:.unshift File.dirname(__FILE__)

module Rewrite
  
  module ByExample
    
    # Matches nil.
    class NilEntity < EntityMatcher
      
      def unfold (sexp)
        {} if sexp.nil?
      end
      
      def fold (enum_of_bindings)
        nil
      end
      
      def to_s
        "nil"
      end
      
    end
    
  end
  
end