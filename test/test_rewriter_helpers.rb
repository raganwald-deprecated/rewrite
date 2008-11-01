require File.dirname(__FILE__) + '/test_helper.rb'

class TestRewriteHelpers < Test::Unit::TestCase
  
  def test_simple_rewrite
    
    assert_equal(
      lambda { |a| a.call }.to_sexp.to_a,
      Rewrite::RewriteVariablesAsThunkCalls.new(:a).process(
        lambda { |a| a }.to_sexp
      ).to_a
    )
    
    assert_equal(
      lambda { |a, b| a.call + b }.to_sexp.to_a,
      Rewrite::RewriteVariablesAsThunkCalls.new(:a).process(
        lambda { |a,b| a + b }.to_sexp
      ).to_a
    )
    
  end
  
  def test_nested_rewrite
    
    assert_equal(
      lambda { |a| lambda { |b| b } }.to_sexp.to_a,
      Rewrite::VariableRewriter.new(:a, s(:dvar, :a)).process(
        lambda { |a| lambda { |b| b } }.to_sexp
      ).to_a
    )
    
    assert_equal(
      lambda { |a| lambda { |b| a.call } }.to_sexp.to_a,
      Rewrite::RewriteVariablesAsThunkCalls.new(:a).process(
        lambda { |a| lambda { |b| a } }.to_sexp
      ).to_a
    )
    
    assert_equal(
      lambda { |a| lambda { |a| a } }.to_sexp.to_a,
      Rewrite::RewriteVariablesAsThunkCalls.new(:a).process(
        lambda { |a| lambda { |a| a } }.to_sexp
      ).to_a
    )
    
  end
  
  def test_multiple_rewites
    
    assert_equal(
      lambda { |a,b| a.call || b.call }.to_sexp.to_a,
      Rewrite::RewriteVariablesAsThunkCalls.new(:a,:b).process(
        lambda { |a,b| a || b }.to_sexp
      ).to_a
    )
    
  end
  
end