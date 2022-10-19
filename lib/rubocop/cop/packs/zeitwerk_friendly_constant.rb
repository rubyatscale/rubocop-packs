# typed: false
# frozen_string_literal: true

# Copyright 2022 Shopify Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
# to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
# THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

# This cop was originally shared by Shopify in a gist: https://gist.github.com/rafaelfranca/8f045e3560b2b45fa67cdd1f13285075,
# hence the inclusion of their LICENSE.
module RuboCop
  module Cop
    module Packs
      # This cop checks that every constant defined in a file matches the
      # file name such that it is independently loadable by Zeitwerk.
      #
      # @example
      #
      #   Good
      #
      #     # /some/directory/foo.rb
      #     module Foo
      #     end
      #
      #     # /some/directory/foo.rb
      #     module Foo
      #       module Bar
      #       end
      #     end
      #
      #     # /some/directory/foo/bar.rb
      #     module Foo
      #       module Bar
      #       end
      #     end
      #
      #   Bad
      #
      #     # /some/directory/foo.rb
      #     module Bar
      #     end
      #
      #     # /some/directory/foo/bar.rb
      #     module Foo
      #       module Bar
      #       end
      #
      #       module Baz
      #       end
      #     end
      #
      class ZeitwerkFriendlyConstant < Cop
        MSG = 'Constant name does not match filename.'
        CLASS_MESSAGE = 'Class name does not match filename.'
        MODULE_MESSAGE = 'Module name does not match filename.'
        INCOMPATIBLE_FILE_PATH_MESSAGE = 'Constant names are mutually incompatible with file path.'

        CONSTANT_NAME_MATCHER = /\A[[:upper:]_]*\Z/.freeze
        CONSTANT_DEFINITION_TYPES = %i[module class casgn].freeze

        def relevant_file?(file)
          super && (File.extname(file) == '.rb')
        end

        def investigate(processed_source)
          return if processed_source.blank?

          filename = processed_source.buffer.name
          path_segments = filename.delete_suffix('.rb').split('/').map! { |dir| camelize(dir) }

          common_anchors = nil

          each_nested_constant(processed_source.ast) do |node, nesting|
            anchors = nesting.anchors(path_segments)

            if anchors.empty?
              add_offense(node, message: offense_message(node))
            else
              common_anchors ||= anchors

              if (common_anchors &= anchors).empty?
                # Add an offense if there is no common anchor among constants.
                add_offense(node, message: INCOMPATIBLE_FILE_PATH_MESSAGE)
              end
            end
          end
        end

        private

        # Traverse the AST from node and yield each constant, along with its
        # nesting: an array of class/module names within which it is defined.
        def each_nested_constant(node, nesting = Nesting.new([]), &block)
          nesting.push(node) if constant_definition?(node)

          any_yielded = node.child_nodes.map do |child_node|
            each_nested_constant(child_node, nesting.dup, &block)
          end.any?

          # We only yield "leaves", i.e. constants that have no other nested
          # constants within themselves. To do this we return true from this
          # method if it itself has yielded, and only yield from parents if all
          # recursive calls did not return true (i.e. they did not yield).
          if !any_yielded && constant_definition?(node)
            yield(node, nesting)
            true
          else
            any_yielded
          end
        end

        def constant_definition?(node)
          CONSTANT_DEFINITION_TYPES.include?(node.type)
        end

        def offense_message(node)
          case node.type
          when :module
            MODULE_MESSAGE
          when :class
            CLASS_MESSAGE
          end
        end

        def camelize(path_segment)
          path_segment.split('_').map! do |segment|
            acronyms.key?(segment) ? acronyms[segment] : segment.capitalize
          end.join
        end

        def acronyms
          @acronyms ||= cop_config['Acronyms'].to_h do |acronym|
            [acronym.downcase, acronym]
          end
        end

        Nesting = Struct.new(:namespace) do
          def push(node)
            self.namespace += [node]
            @constants = nil
          end

          def constants
            @constants ||= namespace.flat_map { |node| constant_name(node).split('::') }
          end

          # For a nesting like ["Foo", "Bar"] and path segments ["", "Some",
          # "Dir", "Foo", "Bar"], return an array of all possible "anchors" of the
          # nesting within the segments, if any (in this case, [3]).
          def anchors(path_segments)
            (1..constants.length).each_with_object([]) do |i, anchors|
              if path_segments[(path_segments.size - i)..-1] == constants[0, i]
                anchors << i
              end
            end
          end

          def constant_name(node)
            if (defined_module = node.defined_module)
              defined_module.const_name
            else
              name = node.children[1].to_s
              name = name.split('_').map(&:capitalize!).join if CONSTANT_NAME_MATCHER.match?(name)
              name
            end
          end
        end
      end
    end
  end
end
