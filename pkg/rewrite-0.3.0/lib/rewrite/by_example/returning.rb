$:.unshift File.dirname(__FILE__)

module Rewrite
  
  module ByExample
    
    module Returning
      module ClassMethods
        def returning(something)
          yield something if block_given?
          something
        end
      end
      
      module InstanceMethods
        def returning(something)
          ClassMethods.returning(something)
        end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
    
  end
  
end