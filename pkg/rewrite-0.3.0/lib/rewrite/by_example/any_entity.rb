$:.unshift File.dirname(__FILE__)

require File.expand_path(File.dirname(__FILE__) +'/entity_matcher.rb')

module Rewrite
  
  module ByExample
    
    # Matches any entity and optionally binds that entity's value to a name in the
    # unfolded result. AnyEntity.new('name') binds whatever it matches to
    # 'name'.
    #
    # Not isomorphic to BindSequence: if you want to match a sequence
    # consisting of exactly one entity and bind that to 'name', you need
    # to combine AnyEntity with LengthOne:
    #
    #   LengthOne.new(AnyEntity.new('name))
    class AnyEntity < EntityMatcher
      
      def unfold (sexp)
        {}
      end
      
      def to_s
        '__'
      end
      
    end
    
  end
  
end