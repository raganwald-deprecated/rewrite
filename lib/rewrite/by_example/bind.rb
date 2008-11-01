$:.unshift File.dirname(__FILE__)

require File.expand_path(File.dirname(__FILE__) +'/entity_matcher.rb')

module Rewrite
  
  module ByExample
    
    # Abstract class that matches any entity and optionally binds that entity's 
    # value to a name in the unfolded result. Useful for creating classes that bind
    # and match simultaneously
    class Bind < EntityMatcher
      
      attr_accessor :name, :entity_matcher
      
      def initialize(name, entity_matcher)
        self.name = name.to_sym
        self.entity_matcher = entity_matcher
      end
      
      def unfold (sexp)
        { self.name => sexp } if entity_matcher.unfold(sexp)
      end
      
      def fold (enum_of_bindings)
        enum_of_bindings[self.name]
      end
      
      def to_s
        if name
          "#{entity_matcher.to_s} => #{name.inspect}"
        else
          '*'
        end
      end
      
    end
    
  end
  
end