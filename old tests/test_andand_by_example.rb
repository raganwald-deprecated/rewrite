require File.dirname(__FILE__) +  '/test_helper.rb'

include Rewrite::With

class Symbol
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end
end

module Rewrite
  
  module ByExample

    class AndandByExample < Test::Unit::TestCase
      
      def test_no_parameters_no_block
        andand = Unhygienic.
          from(:receiver, :message, [:parameters]) {
            receiver.andand.message
          }.
          to {
            lambda { |andand_temp|
              andand_temp.message if andand_temp
            }.call(receiver)
          }
        with(andand) do
          assert_equal('1', 1.andand.to_s)
          assert_equal('1', 1.andand.to_s())
          assert_nil(nil.andand.to_s)
          assert_nil(nil.andand.to_s())
        end
      end
      
      def test_parameters_no_block
        andand = Unhygienic.
          from(:receiver, :message, [:parameters]) {
            receiver.andand.message(parameters)
          }.
          to {
            lambda { |andand_temp|
              andand_temp.message(parameters) if andand_temp
            }.call(receiver)
          }
        with(andand) do
          assert_equal('Hello' + ' World', 'Hello'.andand + ' World')
          assert_nil(nil.andand + ' World')
        end
      end
      
      def test_no_parameters_block_pass
        andand = Unhygienic.
          from(:receiver, :message, :block) {
            receiver.andand.message(&block)
          }.
          to {
            lambda { |andand_temp|
              andand_temp.message(&block) if andand_temp
            }.call(receiver)
          }
        with(andand) do
          assert_equal(
            (1..3).map(&:to_s), 
            (1..3).andand.map(&:to_s)
          )
        end
      end
      
      def test_parameters_block_pass
        andand = Unhygienic.
          from(:receiver, :message, [:params], :block) {
            receiver.andand.message(:params, &block)
          }.
          to {
            lambda { |andand_temp|
              andand_temp.message(:params, &block) if andand_temp
            }.call(receiver)
          }
        with(andand) do
          assert_equal(
            (1..3).inject(0, &:+), 
            (1..3).andand.inject(0, &:+)
          )
        end
      end
      
      def test_no_parameters_block
        andand = Unhygienic.
          from(:receiver, :message, [:params], :body ) {
            receiver.andand.message { |params| body }
          }.
          to {
            lambda { |andand_temp|
              andand_temp.message { |params| body } if andand_temp
            }.call(receiver)
          }
        with(andand) do
          assert_equal(
            (1..5).inject { |a,b| a * b },
            (1..5).andand.inject { |a,b| a * b }
          )
        end
      end
      
      def test_parameters_block
        andand = Unhygienic.
          from(:receiver, :message, [:message_params], [:block_params], :block_body ) {
            receiver.andand.message(message_params) { |block_params| block_body }
          }.
          to {
            lambda { |andand_temp|
              andand_temp.message(message_params) { |block_params| block_body } if andand_temp
            }.call(receiver)
          }
        with(andand) do
          assert_equal(
            (1..5).inject(1) { |a,b| a * b },
            (1..5).andand.inject(1) { |a,b| a * b }
          )
          assert_not_equal(
            (1..5).inject(2) { |a,b| a * b },
            (1..5).andand.inject(2) { |a,b| a * b }
          )
          assert_not_equal(
            (1..5).inject(1) { |a,b| a * b },
            (1..5).andand.inject(2) { |a,b| a * b }
          )
        end
      end
      
    end
    
  end
  
end