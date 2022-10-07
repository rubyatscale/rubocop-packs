# frozen_string_literal: true

module RuboCop
  module Cop
    module Modularization
      # This cop states that public API should live on class methods, which are more easily statically analyzable,
      # searchable, and typically hold less state.
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
      # @example AcceptableParentClasses: [T::Enum, T::Struct, Struct, OpenStruct] (default)
      #   You can define `AcceptableParentClasses` which are a list of classes that, if inherited from, non-class methods are permitted.
      #   This is useful when value objects are a part of your public API.
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   class Foo < T::Enum
      #     const :blah
      #   end
      #
      class ClassMethodsAsPublicApis < Base
        def on_def(node)
          # This cop only applies for ruby files in `app/public`
          return if !processed_source.file_path.include?('app/public')

          # Looked at https://www.rubydoc.info/gems/rubocop/RuboCop/Cop/Lint/MissingSuper source code as inspiration for htis part.
          class_node = node.each_ancestor(:class).first
          module_node = node.each_ancestor(:module).first
          parent_class = class_node&.parent_class || module_node&.parent

          acceptable_parent_classes = cop_config['AcceptableParentClasses'] || []
          
          # Used this PR as inspiration to check if we're within a `class << self` block
          uses_implicit_static_methods = node.each_ancestor(:sclass).first&.identifier&.source == 'self'
          class_is_allowed_to_have_instance_methods = acceptable_parent_classes.include?(parent_class&.const_name)
          return if uses_implicit_static_methods || class_is_allowed_to_have_instance_methods

          add_offense(
            node.source_range,
            message: format(
              'Top-level files in the public/ folder may only define class methods.'
            )
          )
        end
      end
    end
  end
end
