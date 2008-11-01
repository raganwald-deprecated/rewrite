$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module Rewrite

  module Prelude
  
    # Adds a polite method invocation to Ruby:
    #
    #   with(try) do
    #     ...
    #     @phone = Location.find(:first, ...elided... ).try.phone
    #     ...
    #   end
    #
    # Based on "try()":http://ozmm.org/posts/try.html by Chris Wanstrath
    #
    # It also works with parameters, blocks, and procs passed as blocks.
    #
    # Works by rewriting expressions like:
    #
    #   numbers.try(:sum)
    #
    # Into:
    #
    #  lambda { |receiver, message|
    #    receiver.send message if receiver.respond_to? message
    #  }.call(numbers, :sum)
    #
    # See also: Please, Andand
    #
    class Try < SexpProcessor
    
      def process_call(exp)
        # [:call, [:dvar, :foo], :try, [:array, [:lit, :bar]]]
        exp.shift
        # [[:dvar, :foo], :try, [:array, [:lit, :bar]]]]
        receiver_sexp = exp.first
        if exp[1] == :try
          message_expression = exp[2][1]
          exp.clear
          s(:call, 
            s(:iter, 
              s(:fcall, :lambda), 
              s(:masgn,
                s(:array,
                  s(:dasgn_curr, :receiver),
                  s(:dasgn_curr, :message)
                )
              ), 
              s(:if, 
                s(:call, s(:dvar, :receiver), :respond_to?, s(:array, s(:dvar, :receiver))), 
                s(:call, s(:dvar, :receiver), :send, s(:array, s(:dvar, :message))),
                s(:nil)
              )
            ), 
            :call, 
            s(:array, 
              process_inner_expr(receiver_sexp), # [:dvar, :foo]
              process_inner_expr(message_expression)
            )
          )
        else
          # pass through
          begin
            s(:call,
              *(exp.map { |inner| process_inner_expr inner })
            )
          ensure
            exp.clear
          end
        end
      end
      
      private 
      
      def process_inner_expr(inner)
          inner.kind_of?(Array) ? process(inner) : inner
      end
      
    end
  
  end

end