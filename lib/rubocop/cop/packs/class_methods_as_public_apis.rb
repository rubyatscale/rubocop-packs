# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Packs
      # This cop states that public API should live on class methods, which are more easily statically analyzable,
      # searchable, and typically hold less state.
      #
      # Options:
      #
      # * `AcceptableParentClasses`: A list of classes that, if inherited from, non-class methods are permitted (useful when value objects are a part of your public API)
      # * `AcceptableMixins`: A list of modules that, if included, non-class methods are permitted
      #
      # @example
      #
      #   # bad
      #   # packs/foo/app/public/foo.rb
      #   module Foo
      #     def blah
      #     end
      #   end
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   module Foo
      #     def self.blah
      #     end
      #   end
      #
      class ClassMethodsAsPublicApis < Base
        extend T::Sig

        sig { returns(T::Boolean) }
        def support_autocorrect?
          false
        end

        sig { params(node: T.untyped).void }
        def on_def(node)
          # This cop only applies for ruby files in `app/public`
          return if !processed_source.file_path.include?('app/public/')

          # Looked at https://www.rubydoc.info/gems/rubocop/RuboCop/Cop/Lint/MissingSuper source code as inspiration for htis part.
          class_node = node.each_ancestor(:class).first
          module_node = node.each_ancestor(:module).first
          parent_class = class_node&.parent_class || module_node&.parent

          acceptable_parent_classes = cop_config['AcceptableParentClasses'] || []

          uses_implicit_static_methods = node.each_ancestor(:sclass).first&.identifier&.source == 'self'
          class_is_allowed_to_have_instance_methods = acceptable_parent_classes.include?(parent_class&.const_name)
          return if uses_implicit_static_methods || class_is_allowed_to_have_instance_methods

          is_sorbet_interface_or_abstract_class = !module_node.nil? && module_node.descendants.any? { |d| d.is_a?(RuboCop::AST::SendNode) && (d.method_name == :interface! || d.method_name == :abstract!) }
          return if is_sorbet_interface_or_abstract_class
          return if node_includes_acceptable_mixin?(class_node || module_node)

          add_offense(
            node.source_range,
            message: format(
              "Public API method must be a class method (e.g. `self.#{node.method_name}(...)`)"
            )
          )
        end

        private

        sig { params(node: T.untyped).returns(T::Boolean) }
        def node_includes_acceptable_mixin?(node)
          acceptable_mixins = cop_config['AcceptableMixins'] || []
          return false if node.nil?

          node.descendants.any? do |d|
            d.is_a?(RuboCop::AST::SendNode) &&
              d.method_name == :include &&
              d.arguments.count == 1 &&
              d.arguments.first.is_a?(RuboCop::AST::ConstNode) &&
              acceptable_mixins.include?(d.arguments.first.const_name)
          end
        end
      end
    end
  end
end
