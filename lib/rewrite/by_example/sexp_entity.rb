$:.unshift File.dirname(__FILE__)

module Rewrite
  
  module ByExample
    
    # A SexpEntity is a matcher that is initialized with example sexps,
    # so it matches a literal tree. I think SexpEntity is right, however
    # not all things you build with ObjectToSequence are Sexps?
    class SexpEntity < EntityMatcher
      
      attr_accessor :sequence
      
      def initialize(*foo)
        raise "refactor to ObjectToMatcher" unless foo.empty?
        raise "refactor to ObjectToMatcher" if block_given?
      end
      
      def self.for_sequence(sequence)
        s = SexpEntity.new
        s.sequence = sequence
        return s
      end
      
      def unfold (sexp)
        if sexp.kind_of? Array
          self.sequence.unfolders_by_length(sexp.length).each { |unfolder|
            unfolded = unfolder.call(sexp)
            return unfolded if unfolded && (predicate.nil? || predicate.call(unfolded))
          }
          nil
        end
      end
      
      def fold (enum_of_bindings)
        self.sequence.fold(enum_of_bindings)
      end
      
      def to_s
        "s( #{sequence.to_s} )"
      end
      
      def self.proc_capturer
        SexpEntity.new(:proc, nil,  Bind.new(:sexp, AnyEntity.new))
      end
      
    end
    
  end
  
end