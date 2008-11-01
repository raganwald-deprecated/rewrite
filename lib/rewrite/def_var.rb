$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'

module Rewrite
    
  # Hygienically define a variable to be used in a chunk of code.
  #
  #   Defvar.new(:name, definition).process(exp)
  #     => lambda { |name|
  #          exp
  #        }.call(definition)
  #
  # This is useful when you want to wrap some code in a let.
  #
  # There's an olptimization so that you can nest it without penalty:
  #
  #
  #   Defvar.new(:name1, definition1).process(
  #     Defvar.new(:name2, definition2).process(exp)
  #   ) => lambda { |name1, name2|
  #          exp
  #        }.call(definition1, definition2)
  #
  class DefVar
    
    def initialize(sym, sexp)
      @sym, @sexp = sym, sexp
    end
    
    def process(sexp)
      if sexp.length >= 3 && sexp[0] == :call && sexp[2] == :call &&
          (callee = sexp[1]) && callee.length >= 4 && callee[0] == :iter && callee[1].to_a == [:fcall, :lambda]
        parameters = callee[2]
        if parameters.nil?
          callee[2] = s(:dasgn_curr, @sym)
          s(:call,
            callee,
            :call,
            s(:array, @sexp)
          )
        elsif parameters[0] == :dasgn || parameters[0] == :dasgn_curr
          callee[2] = s(:masgn,
            s(:array,
              s(:dasgn_curr, parameters[1]),
              s(:dasgn_curr, @sym)
            )
          )
          s(:call,
            callee,
            :call,
            sexp[3] + [ @sexp ]
          )
        elsif parameters[0] == :masgn
          callee[2][1] << s(:dasgn_curr, @sym)
          s(:call,
            callee,
            :call,
            sexp[3] + [ @sexp ]
          )
        else
          raise "Confused by #{Ruby2Ruby.new.process(parameters)}"
        end
      else
        s(:call,
          s(:iter,
            s(:fcall, :lambda),
            s(:dasgn_curr, @sym),
            sexp
          ),
          :call,
          s(:array, @sexp)
        )
      end
    end
    
  end
  
end