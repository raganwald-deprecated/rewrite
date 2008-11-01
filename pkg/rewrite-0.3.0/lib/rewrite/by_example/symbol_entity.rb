$:.unshift File.dirname(__FILE__)

module Rewrite
  
  module ByExample
    
    # Matches a specific symbol: SymbolEntity.new(:foo) matches :foo.
    #
    # Note that this is not the same thing as matching the use of a symbol in Ruby
    # code, because a literal symbol in Ruby is actually represented as:
    #
    #   s(:lit, :foo)
    class SymbolEntity < EntityMatcher
      
      attr_accessor :symbol
      
      def initialize(symbol)
        self.symbol = symbol
      end
      
      def unfold (sexp)
        {} if self.symbol == sexp
      end
      
      def fold (enum_of_bindings)
        self.symbol
      end
      
      def to_s
        ":#{self.symbol.to_s}"
      end
      
    end
    
  end
  
end