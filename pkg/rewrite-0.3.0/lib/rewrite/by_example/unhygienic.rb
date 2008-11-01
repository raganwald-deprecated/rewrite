$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'sexp_processor'

module Rewrite
  
  module ByExample
    
    #--
    #
    # TODO: 'mixed modes' such that we can write string_to_proc as an unhygienic
    # TODO: composable unhygienics (entity matchers are already composable)
    # TODO: how would we rename variable references safely with unhygienics? CSS model (heterogeneous patterns)? Combinatoral?
    # TODO: What happens if scoping changes sufficiently that matching dvars, vcalls and so-forth changes between the macro definition and the macro *use*?
    class Unhygienic < SexpProcessor
      
      attr_accessor :from_unfolder, :to_folder, :bind_arguments
      
      def from(*bind_arguments, &proc)
        self.bind_arguments = bind_arguments
        self.from_unfolder = ObjectToMatcher.binding(*self.bind_arguments).from_example(&proc)
        self
      end
      
      def to(&proc)
        self.to_folder = ObjectToMatcher.binding(*self.bind_arguments).from_example(&proc)
        self
      end
      
      def self.from(*bind_arguments, &proc)
        self.new.from(*bind_arguments, &proc)
      end
      
      def process(exp)
        raise "Need a from unfolder" unless from_unfolder
        raise "Need a to folder" unless to_folder
        Rewrite.recursive_s(process_inner(exp))
      end
      
      def process_inner(exp)
        if exp.is_a? Array
          exp = exp.map { |sub_exp| process_inner(sub_exp) }
        end
        if unfolded = from_unfolder.unfold(exp) 
          if refolded = to_folder.fold(unfolded)
            exp = refolded
          end
        end
        exp
      end
      
    end
    
  end
  
end