$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
  
require 'rubygems'
require 'ruby2ruby'

Dir["#{File.dirname(__FILE__)}/rewrite/*.rb"].each do |element|
   require element
end

# Rewrite is the namespace for everything provided by the rewrite gem (http://rewrite.rubyforge.org).
#
# Rewrite is a framework for rewriting Ruby code before it is interpreted. This is useful for creating
# abstractions that require non-eager evaluation, optimizing certain kinds of code, and creating even
# more expressive domain-specific languages.
#
# In its basic form, use Rewrite like this:
#
#   Rewrite.with(rewriter1, rewriter2, rewriter3) do
#     class MyClass
#       # ...
#     end
#   end
#
# Rewrite will take all the code between the do and end keywords and rewrite it using
# the declared rewriters (rewriter1, rewriter2, and rewriter3).
#
# One of the benefits of this approach is that the effect of the rewriters is limited
# to the blocks of code you choose to rewrite. For example, the andand gem
# (http://andand.rubyforge.org) uses "Classical Metaprogramming:" it modifies the Object
# and NilClass classes to do its thing, which means that if you require andand anywhere
# in your project, you have andand everywhere in your project and (if you are writing a
# gem or rails plug in) your downstream clients all have andand as well.
#
# Whereas Rewrite provides its own version of andand, Rewrite::Prelude::Andand. There are
# some important difference that have to do with eager evaluation vs. call by name, but
# especially interesting is that when you write:
#
#   class MyClass
#     include Rewrite
#     include Rewrite::Prelude
#     with (andand) do
#       # ...
#       foo.andand.bar(42)
#       # ...
#     end
#   end
#
# You are not modifying any core classes to make foo.andand.bar(42) work.
#
# See Rewrite::Prelude for a complete list of rewriters built into the Rewrite gem for your use.
module Rewrite
  
  module ClassMethods
      
    # Provide a symbol that is extremely unlikely to be used elsewhere.
    # 
    # Rewriters use this when they need to name something. For example,
    # Andand converts code like this:
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
    # It uses Rewrite.gensym to generate __1234567890__.
    #
    def gensym
      :"__#{Time.now.to_i}#{rand(100000)}__"
    end
  
    # Convert an expression to a sexp by taking a block and stripping\
    # the outer prc from it.
    def sexp_for &proc
      sexp = proc.to_sexp
      return if sexp.length != 3
      return if sexp[0] != :proc
      return unless sexp[1].nil?
      sexp[2]
    end
    
    # Convert an expression to a sexp and then the sexp to an array.
    # Useful for tests where you want to compare results.
    def arr_for &proc
      sexp_for(&proc).to_a
    end
    
    # Convert an object of some type to a sexp, very useful when you have a sexp
    # expressed as a tree of arrays.
    def recursive_s(node)
      if node.is_a? Array
        s(*(node.map { |subnode| recursive_s(subnode) }))
      else
        node
      end
    end
    
  end
  extend ClassMethods
  
end