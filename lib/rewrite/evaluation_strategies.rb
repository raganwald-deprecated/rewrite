$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'

module Rewrite
  
  # Takes a sexp representing a lambda and rewrites all of its parameter references as thunk calls.
  #
  # Example:
  #
  #   lambda { |a,b| a + b }
  #     => lambda { |a,b| a.call + b.call }
  #
  class RewriteParametersAsThunkCalls
  
    def sexp(exp)
      if exp.kind_of? Array
        s(*exp.map { |e| sexp(e) })
      else
        exp
      end
    end
  
    def process(sexp)
      raise "Expected a proc" unless sexp[0] == :proc
      raise "Expected a proc with arity >= 1" if sexp[1] == nil
      arguments = sexp[1]
      variable_symbols = if arguments[0] == :dasgn || arguments[0] == :dasgn_curr
        [arguments[1]]
      elsif arguments[0] == :masgn
        arguments[1][1..-1].map { |pair| pair[1] }
      else
        raise "don't know how to extract paramater names from #{arguments}"
      end
      
      s(:iter,
        s(:fcall, :lambda),
        sexp(arguments),
        variable_symbols.inject(sexp[2]) { |result, variable|
          VariableRewriter.new(variable, s(:call, s(:dvar, variable), :call)).process(eval(result.inspect))
        }
      )
      
    end
  
  end
    
  # Initialize with a list of names, e.g.
  #   CallByThunk.new(:foo, :bar)
  #
  # It then converts expressions of the form:
  #
  #    foo(expr1, expr2, ..., exprn)
  #
  # into:
  #
  #    foo.call( lambda { expr1 }, lambda { expr2 }, ..., lambda { exprn })
  #
  # This is handy when combined with RewriteVariablesAsThunkCalls in the following
  # manner: if you rewrite function invocations with CallByThunk and also rewrite the
  # function's body to convert variable references into thunk calls, you now have a
  # function with call-by-name semantics
  #
  class CallByThunk < SexpProcessor
    
    def initialize(*functions_to_thunkify)
      @functions_to_thunkify = functions_to_thunkify
      super()
    end
    
    def process_fcall(exp)
      qua = exp.dup
      exp.shift
      name = exp.shift
      if @functions_to_thunkify.include? name
        thunked = s(:call, s(:dvar, name), :call)
        unless exp.empty?
          arguments = exp.shift
          raise "Do not understand arguments #{arguments}" unless arguments[0] == :array
          arguments.shift
          thunked_arguments = s(:array)
          until arguments.empty?
            thunked_arguments <<  s(:iter, s(:fcall, :lambda), nil, process(arguments.shift))
          end
          thunked << thunked_arguments
        end
      else
        thunked = s(:fcall, name) # :fcall, name_of_the_function
        thunked << process(exp.shift) unless exp.empty?
      end
      thunked
    end
    
  end
    
  # Initialize with a list of names, e.g.
  #
  #   CallSplattedByThunk.new(:foo, :bar)
  #
  # It then converts expressions of the form:
  #
  #    foo(expr1, expr2, ..., exprn)
  #
  # into:
  #
  #    foo.call( 
  #      CallSplattedByThunk::Parameters.new(
  #        lambda { expr1 }, lambda { expr2 }, ..., lambda { exprn }
  #      )
  #    )
  #
  # This is allows you to create call-by-name pseudo-functions that take
  # an arbitrary number of arguments
  #
  class CallSplattedByThunk < SexpProcessor
    
    def initialize(*functions_to_splat_thunkify)
      @functions_to_splat_thunkify = functions_to_splat_thunkify
      super()
    end
    
    def process_fcall(exp)
      qua = exp.dup
      exp.shift
      name = exp.shift
      if @functions_to_splat_thunkify.include? name
        thunked = s(:call, s(:dvar, name), :call)
        unless exp.empty?
          arguments = exp.shift
          raise "Do not understand arguments #{arguments}" unless arguments[0] == :array
          thunked << s(:array,
            s(:call,
              s(:colon2, s(:colon2, s(:const, :Rewrite), :CallSplattedByThunk), :Parameters),
              :new,
              arguments[1..-1].inject(s(:array)) { |arr, arg| 
                arr << s(:iter, s(:fcall, :lambda), nil, process(arg)) 
              }
            )
          )
        end
      else
        thunked = s(:fcall, name) # :fcall, name_of_the_function
        thunked << process(exp.shift) unless exp.empty?
      end
      thunked
    end
    
    class Parameters
      
      include Enumerable
      
      def initialize(*lambdas)
        @lambdas = *lambdas
      end
      
      def each
        lambdas.each do |l|
          yield l.call
        end
      end
      
    end
    
  end
  
end