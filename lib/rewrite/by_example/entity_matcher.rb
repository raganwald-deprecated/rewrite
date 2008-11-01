$:.unshift File.dirname(__FILE__)

module Rewrite
  
  module ByExample
    
    # Matches a single something against a sexp
    # such as an array or a literal symbol
    class EntityMatcher
      
      attr_accessor :predicate
      
      def such_that!(&predicate_clause)
        self.predicate = predicate_clause
        self
      end
      
      # takes a sexp and returns nil or an enumeration of
      # bindings, typically as a hash. Note that the empty hash
      # is truthy, and this is what we want: it means a match
      # that doesn't perform any bindings
      #
      # Note the identity: if x.fold(enum_of_bindings) is not nil, 
      # then enum_of_bindings == x.unfold(x.fold(enum_of_bindings))
      def unfold(sexp)
        raise 'implemented by includer'
      end
      remove_method :unfold
      
      # takes an enumeration of bindings and returns nil or a sexp.
      #
      # Note the identity: if x.unfold(sexp) is not nil, then
      # sexp == x.fold(x.unfold(sexp))
      def fold(enum_of_bindings)
        raise 'implemented by includer'
      end
      remove_method :fold
      
      # advice for unfold
      def after_unfold
        
      end
      
    end
    
  end
  
end