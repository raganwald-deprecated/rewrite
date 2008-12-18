$:.unshift File.dirname(__FILE__)
  
require 'rubygems'
require 'ruby2ruby'

module Rewrite
  
  module With
    
    def self.with(*sexp_processors, &body)
      ruby = expand_with(*sexp_processors, &body)
      eval(ruby, body.binding())
    end
    
    def self.expand_with(*sexp_processors, &body)
      rewritten = sexp_processors.flatten.inject(body.to_sexp.last) { |sexp, sexp_processor_parameter|  
        if sexp_processor_parameter.respond_to?(:new) && sexp_processor_parameter.kind_of?(Class)
          sexp_processor = sexp_processor_parameter.new
        else
          sexp_processor = sexp_processor_parameter
        end
        sexp_processor.process(sexp)
      }
      p rewritten.inspect
      rewritten = eval(rewritten.to_s) # i don't know why i need this!!
      p rewritten.inspect
      Ruby2Ruby.new.process(rewritten)
    end
      
    module ClassMethods
      
      def with(*sexp_processors, &body)
        Rewrite::With.with(sexp_processors, &body)
      end
      
      def expand_with(*sexp_processors, &body)
        Rewrite::With.expand_with(sexp_processors, &body)
      end
      
    end
    
    module InstanceMethods
      
      def with(*sexp_processors, &body)
        Rewrite::With.with(sexp_processors, &body)
      end
      
      def expand_with(*sexp_processors, &body)
        Rewrite::With.expand_with(sexp_processors, &body)
      end
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
    
  end
  
  include With
  
end