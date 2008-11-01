module Rewrite
  
  module Prelude
  
    # See "Macros, Hygiene, and Call By Name in Ruby":http://weblog.raganwald.com/2008/06/macros-hygiene-and-call-by-name-in-ruby.html
    #
    # CalledByName allows you to define your own function-like-things that are called by name rather than
    # by value. Here is a trivial example:
    #
    #    with(
    #      called_by_name(:my_or) { |arg1,  arg2|
    #        if  arg1
    #          true
    #        else
    #          !!arg2
    #        end
    #      }
    #    ) do
    #      ...
    #      my_or(
    #        true, nil.raise_missing_method_exception
    #      )
    #      ...
    #    end
    #
    # First, and most obviously, you get something that looks like a real function. Procs in Ruby are just objects
    # that capture the bindings where theire initializing block was created, and you have to invoke them using #call
    # or #[].
    #
    # Second, and this is the funky bit, parameters inside of your function-like-thing are called by name. Meaning,
    # when you call your function-like-thing, instead of evaluating each parameter's expression and passing its
    # value, Ruby passes the a lambda containing expression itself. The expression is not evaluated until the parpameter is actually used,
    # and if you use it more than once the expression is evaluated more than once. This matters when there are side
    # effects.
    #
    # The example above shows how call-by-name can be used to implement short-circuit evaluation, something that is
    # not possible in Ruby without a lot of boilerplate introducing lambdas. When you call my_or, it evaluates arg1
    # as part of the if statement, that evaluates to true, and it never evaluates arg2. Therefore, it never tries
    # to send a method to nil and thus never raises an exception.
    #
    # Works by rewriting:
    #
    #    with(
    #      called_by_name(:my_or) { |arg1,  arg2|
    #        if  arg1
    #          true
    #        else
    #          !!arg2
    #        end
    #      }
    #    ) do
    #      ...
    #      my_or(
    #        true, nil.raise_missing_method_exception
    #      )
    #      ...
    #    end
    #
    # Into:
    #
    #    lambda { |my_or|
    #      ...
    #      my_or.call(
    #        lambda { true }, lambda { nil.raise_missing_method_exception }
    #      )
    #      ...
    #    }.call(
    #      lambda { |arg1,  arg2|
    #        if arg1.call
    #          true
    #        else
    #          !!arg2.call
    #        end
    #      }
    #    )
    #
    class CalledByName
      
      def splatted?(proc)
        sexp = proc.to_sexp
        raise "Expected a proc" unless sexp[0] == :proc
        raise "Expected a proc with arity >= 1" if sexp[1] == nil
        arguments = sexp[1]
        arguments[0] == :masgn && arguments[1] && arguments[1].respond_to?(:first) && arguments[1].first != :array
      end
      
      def as_lambda(proc_sexp)
        s(:iter,
          s(:fcall, :lambda),
          *proc_sexp[1..-1]
        )
      end
  
      def initialize(name, &proc)
        if splatted?(proc)
          @let = Rewrite::DefVar.new(
            name,
            as_lambda(proc.to_sexp)
          )
          @call_by_thunk = Rewrite::CallSplattedByThunk.new(name) 
        else
          @let = Rewrite::DefVar.new(
            name, 
            Rewrite::RewriteParametersAsThunkCalls.new.process(eval(proc.to_sexp.inspect))
          )
          @call_by_thunk = Rewrite::CallByThunk.new(name) 
        end
      end
  
      def process(exp)
        @let.process(
          @call_by_thunk.process(exp)
        )
      end
  
    end

  end

end