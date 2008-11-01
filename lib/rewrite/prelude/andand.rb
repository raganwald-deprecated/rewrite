$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'sexp'

module Rewrite

  module Prelude
  
    # Adds a guarded method invocation to Ruby:
    #
    #   with(andand) do
    #     ...
    #     @phone = Location.find(:first, ...elided... ).andand.phone
    #     ...
    #   end
    #
    # It also works with parameters, blocks, and procs passed as blocks.
    #
    # Works by rewriting expressions like:
    #
    #   numbers.andand.inject(&:+)
    #
    # Into:
    #
    #  lambda { |__1234567890__|
    #    if __1234567890__.nil?
    #      nil
    #    else
    #      __1234567890__.inject(&:+)
    #    end
    #  }.call(numbers)
    #
    # See also: Please, Try
    #
    class Andand < SexpProcessor
      
      def process_iter(exp)
        exp.shift
        receiver_sexp = exp.first #[:call, [:call, [:lit, 1..10], :andand], :inject]
        if receiver_sexp[0] == :call && matches_andand_invocation(receiver_sexp[1])
          exp.shift
          mono_parameter = Rewrite.gensym()
          s(:call, 
            s(:iter, 
              s(:fcall, :lambda), 
              s(:dasgn_curr, mono_parameter), 
              s(:if, 
                s(:call, s(:dvar, mono_parameter), :nil?), 
                s(:nil), 
                begin
                  s(:iter, 
                    s(:call, 
                      s(:dvar, mono_parameter), 
                      *(receiver_sexp[2..-1].map { |inner| process_inner_expr inner })
                    ), 
                    *(exp.map { |inner| process_inner_expr inner })
                  )
                ensure
                  exp.clear
                end
              )
            ), 
            :call, 
            s(:array, 
              process_inner_expr(receiver_sexp[1][1]) # s(:lit, 1..10)
            )
          )
        else
          begin
            s(:iter,
              *(exp.map { |inner| process_inner_expr inner })
            )
          ensure
            exp.clear
          end
        end
      end
    
      def process_call(exp)
        # s(:call, s(:call, s(:lit, :foo), :andand), :bar)
        exp.shift
        # s(s(:call, s(:lit, :foo), :andand), :bar)
        receiver_sexp = exp.first
        if matches_andand_invocation(receiver_sexp) # s(:call, s(:lit, :foo), :andand)
          exp.shift
          # s( :bar )
          mono_parameter = Rewrite.gensym()
          s(:call,
            s(:iter, 
              s(:fcall, :lambda), 
              s(:dasgn_curr, mono_parameter), 
              s(:if, 
                s(:call, s(:dvar, mono_parameter), :nil?), 
                s(:nil), 
                begin
                  s(:call, 
                    s(:dvar, mono_parameter), 
                    *(exp.map { |inner| process_inner_expr inner })
                  )
                ensure
                  exp.clear
                end
              )
            ), 
            :call, 
            s(:array, 
              process_inner_expr(receiver_sexp[1]) # s(:lit, :foo)
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
    
      def process_block_pass(exp)
        orig = lambda { |exp_dup|
          lambda { Ruby2Ruby.new.process(exp_dup) }
        }.call(exp)
        # [:block_pass, [:lit, :+], [:call, [:call, [:vcall, :foo], :andand], :bar]]
        # [:block_pass, [:lit, :blitz], [:call, [:call, [:vcall, :foo], :andand], :bar, [:array, [:lit, :bash]]]]
        exp.shift
        # [[:lit, :+], [:call, [:call, [:vcall, :foo], :andand], :bar]]
        # [[:lit, :blitz], [:call, [:call, [:vcall, :foo], :andand], :bar, [:array, [:lit, :bash]]]]
        block_exp = process_inner_expr(exp.shift)
        call_exp = exp.shift
        raise "expected block_pass to have a receiver and a call form near #{orig.call}" unless exp.empty?
        # [:call, [:call, [:vcall, :foo], :andand], :bar]
        # [:call, [:call, [:vcall, :foo], :andand], :bar, [:array, [:lit, :bash]]]
        raise 'confused' unless call_exp.shift == :call
        # [[:call, [:vcall, :foo], :andand], :bar]
        # [[:call, [:vcall, :foo], :andand], :bar, [:array, [:lit, :bash]]]
        receiver_sexp = call_exp.first
        if matches_andand_invocation(receiver_sexp) # [:call, [:vcall, :foo], :andand]
          call_exp.shift
          # [:bar]
          # [:bar, [:array, [:lit, :bash]]]
          mono_parameter = Rewrite.gensym()
          s(:call, 
            s(:iter, 
              s(:fcall, :lambda), 
              s(:dasgn_curr, mono_parameter), 
              s(:if, 
                s(:call, s(:dvar, mono_parameter), :nil?), 
                s(:nil), 
                s(:block_pass,
                  block_exp,
                  s(:call, 
                    s(:dvar, mono_parameter), 
                    *(call_exp.map { |inner| process_inner_expr inner })
                  )
                )
              )
            ), 
            :call, 
            s(:array, 
              process_inner_expr(receiver_sexp[1]) # s(:lit, :foo)
            )
          )
        else
          s(:block_pass,
            block_exp,
            s(:call,
              *(call_exp.map { |inner| process_inner_expr inner })
            )
          )
        end
      end
      
      private 
      
      def process_inner_expr(inner)
          inner.kind_of?(Array) ? process(inner) : inner
      end
      
      def matches_andand_invocation(sexp)
        sexp[0] == :call && sexp[2] == :andand
      end
      
    end
  
  end

end