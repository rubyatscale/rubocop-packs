# typed: strict

module RuboCop
  module Cop
    module PackwerkLite
      # This cop helps ensure that packs are depending on packs explicitly.
      #
      # @example
      #
      #   # bad
      #   # packs/foo/app/services/foo.rb
      #   class Foo
      #     def bar
      #       Bar
      #     end
      #   end
      #
      #   # packs/foo/package.yml
      #   # enforces_dependencies: true
      #   # enforces_privacy: false
      #   # dependencies:
      #   #   - packs/baz
      #
      #   # good
      #   # packs/foo/app/services/foo.rb
      #   class Foo
      #     def bar
      #       Bar
      #     end
      #   end
      #
      #   # packs/foo/package.yml
      #   # enforces_dependencies: true
      #   # enforces_privacy: false
      #   # dependencies:
      #   #   - packs/baz
      #   #   - packs/bar
      #
      class Dependency < Base
        extend T::Sig

        sig { returns(T::Boolean) }
        def support_autocorrect?
          false
        end

        sig { params(node: RuboCop::AST::ConstNode).void }
        def on_const(node)
          return if Private.partial_const_reference?(node)

          constant_reference = ConstantResolver::ConstantReference.resolve(node, processed_source)
          return if constant_reference.nil?
          return if constant_reference.referencing_package.name == constant_reference.source_package.name

          # These are cases that don't work yet!!
          # I'll need to look into this more. It's related to inflections but not sure how yet!
          return if constant_reference.constant_name.include?('PncApi')

          is_new_violation = [
            !constant_reference.referencing_package.dependencies.include?(constant_reference.source_package.name),
            constant_reference.referencing_package.enforces_dependencies?,
            !Private.violation_in_package_todo_yml?(constant_reference, type: 'dependency')
          ].all?

          if is_new_violation
            add_offense(
              node.source_range,
              message: format(
                'Dependency violation detected. See https://github.com/Shopify/packwerk/blob/main/RESOLVING_VIOLATIONS.md for help'
              )
            )
          end
        end
      end
    end
  end
end
