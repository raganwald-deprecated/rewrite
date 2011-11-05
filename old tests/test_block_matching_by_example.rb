require File.dirname(__FILE__) +  '/test_helper.rb'

include Rewrite::With

class Symbol
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end
end

module Rewrite
  
  module ByExample

    class TestBlockMatchingByExample < Test::Unit::TestCase
      
      def sexp &proc
        proc.to_sexp[2]
      end
      
      def test_match_message_with_block
        unfolder = ObjectToMatcher.binding(:receiver, :message).from_example { 
          receiver.andand.message { |a,b| a + b } 
        }
        subject = sexp { (1..3).andand.inject { |a,b| a + b }  }
        unfolded = unfolder.unfold(subject)
        assert_not_nil(unfolded)
      end
      
      def test_match_block_body
        unfolder = ObjectToMatcher.binding(:receiver, :message, :block_body).from_example { 
          receiver.andand.message { |a,b| block_body } 
        }
        subject = sexp { (1..3).andand.inject { |a,b| a + b }  }
        unfolded = unfolder.unfold(subject)
        assert_not_nil(unfolded[:block_body])
      end
      
      def test_match_explicit_block_parameters
        unfolder = ObjectToMatcher.binding(:receiver, :message, :block_body, :param1, :param2).from_example { 
          receiver.andand.message { |param1, param2| block_body } 
        }
        subject = sexp { (1..3).andand.inject { |a,b| a + b }  }
        unfolded = unfolder.unfold(subject)
        assert_not_nil(unfolded[:param1])
        assert_not_nil(unfolded[:param2])
      end
      
      #--
      #
      # quite clearly, hard to match parameters, and how do we go back and forth between them
      def test_match_block_parameter_list
        unfolder = ObjectToMatcher.binding(:receiver, :message, :block_body, [:block_params]).from_example { 
          receiver.andand.message { |block_params| block_body } 
        }
        subject = sexp { foo.andand.inject { |a,b| a + b }  }
        unfolded = unfolder.unfold(subject)
        p unfolded[:block_params].inspect
        # block_params matches the entire block expression, in this case: 
        # s([:masgn, [:array, [:dasgn_curr, :a], [:dasgn_curr, :b]]])
        subject2 = sexp { foo.andand.inject { |_| _ * _ }  }
        unfolded2 = unfolder.unfold(subject2)
        p unfolded2[:block_params].inspect
        # block_params matches the entire block expression, in this case: 
        # s([:dasgn_curr, :_])
        subject3 = sexp { foo.andand.inject { 42 }  }
        unfolded3 = unfolder.unfold(subject3)
        p unfolded3[:block_params].inspect
        # block_params matches the entire block expression, in this case: 
        # s(nil)
      end
      
      # def test_match_block_parameter_list
      #   unfolder = ObjectToMatcher.binding(:receiver, :message, :block_body, [:block_params]).from_example { 
      #     receiver.andand.message { |block_params| block_body } 
      #   }
      #   subject = sexp { foo.andand.inject { |a,b| a + b }  }
      #   unfolded = unfolder.unfold(subject)
      #   p unfolded[:block_params].inspect
      #   subject2 = sexp { foo.andand.inject { |_| _ * _ }  }
      #   unfolded2 = unfolder.unfold(subject2)
      #   p unfolded2[:block_params].inspect
      #   assert_not_nil(unfolded)
      # end
      
    end
    
  end
  
end