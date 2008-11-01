$:.unshift File.dirname(__FILE__)

require File.expand_path(File.dirname(__FILE__) +'/any_entity.rb')
require File.expand_path(File.dirname(__FILE__) +'/bind.rb')
require File.expand_path(File.dirname(__FILE__) +'/sexp_entity.rb')

module Rewrite
  
  module ByExample
    
    class LiteralEntity < SexpEntity
      
      def initialize(name = Rewrite.gensym)
        super()
        self.sequence = Composition.new(
          LengthOne.new(ObjectToMatcher.from_object(:lit)),
          LengthOne.new(Bind.new(name, AnyEntity.new))
        )
      end
      
    end
    
  end
  
end