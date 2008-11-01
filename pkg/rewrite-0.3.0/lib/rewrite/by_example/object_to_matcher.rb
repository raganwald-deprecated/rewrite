$:.unshift File.dirname(__FILE__)

require File.expand_path(File.dirname(__FILE__) +'/union_of_entities_sequence.rb')
require File.expand_path(File.dirname(__FILE__) +'/symbol_entity.rb')
require File.expand_path(File.dirname(__FILE__) +'/sexp_entity.rb')
require File.expand_path(File.dirname(__FILE__) +'/returning.rb')

module Rewrite
  
  module ByExample
    
    class ObjectToMatcher
      
      include Returning
      
      attr_reader :binders, :bind_arguments
      
      class << self
        attr_accessor :debug
        debug = false
      end
      
      def self.binding (*bind_arguments)
        if bind_arguments.empty?
          @base_object_to_sequence ||= self.new()
        else
          self.new(*bind_arguments)
        end
      end
      
      def self.noisily
        was = self.debug
        begin
          self.debug = true
          yield
        ensure
          self.debug = was
        end
      end
      
      def self.quietly
        was = self.debug
        begin
          self.debug = false
          yield
        ensure
          self.debug = was
        end
      end
      
      def self.symbol_like_expression_matcher
          @symbol_like_expression_matcher ||= 
            returning(
              quietly do
                self.from_object(
                  s(
                    UnionOfEntitiesSequence.new(:gvar, :dvar, :vcall, :lcall, :lit, :dasgn_curr),
                    Bind.new(:variable_symbol, AnyEntity.new)
                  )
                ) 
              end
            ) do |slem|
              p slem.to_s if self.debug
            end
      end
      
      def self.proc_capturer
        @@proc_capturer ||= self.from_object(
          s(:proc, nil,  Bind.new(:sexp, AnyEntity.new))
        )
      end
      
      def initialize (*bind_arguments)
        @bind_arguments = bind_arguments
        @binders = bind_arguments.map { |arg| bind_arg_to_binder(arg) }
      end
      
      def from_example(&proc)
        if unfolded = self.class.proc_capturer.unfold(proc.to_sexp)
          self.from_object(unfolded[:sexp])
        end
      end
      
      def from_object o
        matcher = convert(o)
        raise "#{o.to_s} => #{matcher.to_s} does not describe a matcher" unless matcher.kind_of? EntityMatcher
        matcher
      end
      
      def self.from_example(&proc)
        (@o2s_from_object ||= self.new).from_example(&proc)
      end
      
      def self.from_object o
        (@o2s_from_object ||= self.new).from_object(o)
      end
      
      def self.from_sexp(*elements)
        from_object(elements)
      end
      
      protected
      
      def convert(o)
        p "***** #{o.to_s}" if self.class.debug
        matcher = if o.kind_of? Sequence
          o
        elsif o.kind_of? EntityMatcher
          o
        elsif o.kind_of? Symbol
          from_symbol(o)
        elsif o.nil?
          NilEntity.new
        elsif o.kind_of? Array
          p "#{o.inspect}.kind_of? Array" if self.class.debug
          from_sexp(o)
        else
          raise "Don't know how to handle #{o.inspect}"
        end
        p "returning #{matcher.to_s} given #{o.to_s}" if self.class.debug
        matcher
      end
      
      private
      
      #--
      #
      # Changed this to avoid matching... but do we need it?
      # When would we match this and not match sexp?
      def from_symbol(sym)
        self.binders.each do |binder|
          if bound_object = binder.call(sym)
            p "handling symbol #{sym.inspect} as bound match #{bound_object.to_s}" if self.class.debug
            return bound_object
          end
        end
        p "handling symbol #{sym.inspect} as itself" if self.class.debug
        SymbolEntity.new(sym)
      end
      
      def from_sexp(sexp)
        self.binders.each do |binder|
          if bound_object = binder.call(sexp)
            p "handling sexp #{sexp.to_s} as bound match #{sexp.to_s}" if self.class.debug
            return bound_object
          end
        end
        p "decomposing sexp #{sexp.to_s}" if self.class.debug
        SexpEntity.for_sequence(
          Composition.new(
            *(sexp.map { |sub_sexp| 
                obj = ObjectToMatcher.binding(*bind_arguments).convert(sub_sexp)
                if obj.kind_of? Sequence
                  obj
                else
                  LengthOne.new(obj)
                end
              }
            )
          )
        )
      end
      
      def bind_arg_to_binder(bind_arg)
        p "trying to make a binder for #{bind_arg.inspect}" if self.class.debug
        if bind_arg.is_a?(Array) && bind_arg.length == 1 && pattern = object_to_pattern(bind_arg.first)
          p "binding sequence pattern #{pattern} for #{bind_arg.inspect}" if self.class.debug
          lambda { |sexp_or_symbol|
            p "trying to match #{sexp_or_symbol} against #{pattern.source}" if self.class.debug
            unfolded = ObjectToMatcher.symbol_like_expression_matcher.unfold(sexp_or_symbol)
            p "unfolded is #{unfolded.inspect}" if self.class.debug
            symbol = unfolded[:variable_symbol] if unfolded
            p "symbol is #{symbol.inspect}" if self.class.debug
            name = symbol.to_s[pattern,1] if symbol
            p "name is #{name.inspect}" if self.class.debug
            if name
              BindSequence.new(name)
            elsif sexp_or_symbol.is_a?(Symbol) && name = sexp_or_symbol.to_s[pattern,1]
              BindSequence.new(name)
            end
          }
        elsif pattern = object_to_pattern(bind_arg)
          p "binding entity pattern #{pattern.source} to #{bind_arg.inspect}" if self.class.debug
          lambda { |sexp_or_symbol|  
            p "trying to match #{sexp_or_symbol} against #{pattern.source}" if self.class.debug
            unfolded = ObjectToMatcher.symbol_like_expression_matcher.unfold(sexp_or_symbol)
            p "unfolded is #{unfolded.inspect}" if self.class.debug
            symbol = unfolded[:variable_symbol] if unfolded
            p "symbol is #{symbol.inspect}" if self.class.debug
            name = symbol.to_s[pattern,1] if symbol
            p "name is #{name.inspect}" if self.class.debug
            if name
              Bind.new(name, AnyEntity.new)
            elsif sexp_or_symbol.is_a?(Symbol) && name = sexp_or_symbol.to_s[pattern,1]
              Bind.new(name, AnyEntity.new)
            end
          }
        else
          raise "unable to make a binder for #{bind_arg.inspect}"
        end
      end
      
      def self.object_to_pattern(pattern_string_or_symbol)
        if pattern_string_or_symbol.is_a?(Regexp)
          pattern_string_or_symbol
        elsif pattern_string_or_symbol.is_a?(String) || pattern_string_or_symbol.is_a?(Symbol)
          Regexp.new("^(#{pattern_string_or_symbol.to_s})$")
        else
          nil
        end
      end
      
      def object_to_pattern(arg)
        self.class.object_to_pattern(arg)
      end
      
    end
    
  end
  
end