$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

Dir["#{File.dirname(__FILE__)}/by_example/*.rb"].each do |element|
   require File.expand_path(element)
end

module Rewrite
  
  #--
  #
  # TODO: ROM, the Ruby Object Model. A completely freking new way to do this.
  module ByExample
    
    module ClassMethods
      
      # Sigh, I know that 'clever' variable names are not helpful, but I *need* to remind
      # myself why I am doing this: Using a ByExample to extract what we want from a sexp
      # is eating my own dog food.
      DOGFOODER = ObjectToMatcher.from_object(
        s(:proc,
          nil,
          Bind.new(:body, AnyEntity.new)
        )
      )
      
      def from(&proc)
        body = DOGFOODER.unfold(proc.to_sexp) or raise "Don't know how to handle #{proc.to_ruby}"
        SexpEntity.from(body)
      end
      
    end
    
    module InstanceMethods
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
  
end