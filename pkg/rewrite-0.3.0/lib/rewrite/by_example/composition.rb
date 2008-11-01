$:.unshift File.dirname(__FILE__)

module Rewrite
  
  module ByExample
    
    # A Composition is an aggregation of Sequence. So where a LengthOne and
    # a BindSequence are both leaves of a sequence tree, a Composition is a
    # node.
    class Composition < Sequence
      attr_reader :sub_sequences, :length_range
      
      def initialize(*sub_sequences)
        @sub_sequences = sub_sequences#.map { |sub| Sequence.from_object(sub) }
        @length_range = range_sum(@sub_sequences)
      end
      
      def unfolders_by_length(length)
        unfolders_by_length_helper(sub_sequences(), length)
      end
      
      def to_s
        sub_sequences.map { |ss| ss.to_s }.join(', ')
      end
      
      def fold(enum_of_bindings)
        sub_sequences.inject(s()) { |refolded, sub_sequence|
          folded = sub_sequence.fold(enum_of_bindings)
          if folded.nil?
            s(*(refolded + [nil]))
          elsif sub_sequence.is_a? LengthOne
            s(*(refolded + [folded]))
          else
            s(*(refolded + folded))
          end
        }
      end
      
      private
    
      def merge_results(result1, result2)
        if result1 && result2
          result = result1.dup
          result2.each do |key, value|
            if result.include?(key)
              return nil unless result[key].eql?(value)
            else
              result[key] = value
            end
          end
          result
        end
      end
      
      def unfolders_by_length_helper(subs, length)
        range_of_lengths = range_sum(subs)
        if !(range_of_lengths === length)
          []
        elsif subs.empty? # implied by the test above # TODO: short blog post about this
          []
        elsif subs.length == 1
          subs.first.unfolders_by_length(length)
        else
          head_subsequence = subs.first
          tail_subsequences = subs[1..-1]
          range_of_tail_lengths = range_sum(tail_subsequences)
          required_head_lengths = (length - range_of_tail_lengths.end)..(length - range_of_tail_lengths.begin)
          head_lengths_to_try = range_intersection(head_subsequence.length_range, required_head_lengths)
          return [] if head_lengths_to_try.begin > head_lengths_to_try.end
          head_lengths_to_try.inject([]) { |accumulated_unfolders_for_entire_composition, length_of_head_subsequence_to_try|
            head_unfolders = head_subsequence.unfolders_by_length(length_of_head_subsequence_to_try)
            tail_unfolders = unfolders_by_length_helper(tail_subsequences, length - length_of_head_subsequence_to_try)
            accumulated_unfolders_for_entire_composition + head_unfolders.inject([]) { |accumulated_unfolders_for_entire_composition2, head_unfolder|
              accumulated_unfolders_for_entire_composition2 + tail_unfolders.map { |tail_unfolder|
                lambda { |arr|
                  head_portion, tail_portion = arr[0,length_of_head_subsequence_to_try], arr[length_of_head_subsequence_to_try..-1]
                  merge_results(
                    head_unfolder.call(head_portion), 
                    tail_unfolder.call(tail_portion)
                  )
                }
              }
            }
          }
        end
      end
      
      def range_intersection(range1, range2)
        ([range1.begin, range2.begin].max)..([range1.end, range2.end].min)
      end
      
      def range_sum(enumerable_of_sequences)
        enumerable_of_sequences.inject(0..0) { |total_range, each_seq|
          each_range = each_seq.length_range
          (total_range.begin + each_range.begin)..(total_range.end + each_range.end)
        }
      end
      
      
    end
    
  end
  
end