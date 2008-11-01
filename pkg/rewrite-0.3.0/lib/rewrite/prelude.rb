$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

Dir["#{File.dirname(__FILE__)}/prelude/*.rb"].each do |element|
   require element
end

    
module Rewrite
  
  # Module containing standard rewriting features. For more information about each feature, go directly to the class,
  # such as Andand or CalledByName. If you <tt>include Rewrite::Prelude</tt>, you get some methods as sugar. For a
  # list of those methods, go to InstanceMethods.
  module Prelude
    
    module ClassMethods #:nodoc: all
      
    end
    
    module InstanceMethods
      
      # Create a new CalledByName rewriter
      def called_by_name(name, &proc)
        CalledByName.new(name, &proc)
      end
      
      # Instantiate Andand rewriting
      def andand()
        Andand.new
      end
      
      # Instantiate Please rewriting
      def please()
        Please.new
      end
      
      # Instantiate Try rewriting
      def try()
        Try.new
      end
      
      def standards()
        [andand(), please(), try()]
      end
      
    end
    
    def self.included(receiver) #:nodoc: all
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
    
  end
  
end