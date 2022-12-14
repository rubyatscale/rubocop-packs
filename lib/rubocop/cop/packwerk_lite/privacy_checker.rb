# typed: strict

module RuboCop
  module Cop
    module PackwerkLite
      # This cop helps ensure that packs are using public API of other systems
      # The following examples assume this basic setup.
      #
      # @example
      #   # packs/bar/app/public/bar.rb
      #   class Bar
      #     def my_public_api; end
      #   end
      #
      #   # packs/bar/app/services/private.rb
      #   class Private
      #     def my_private_api; end
      #   end
      #
      #   # packs/bar/package.yml
      #   # enforces_dependencies: false
      #   # enforces_privacy: true
      #
      #   # bad
      #   # packs/foo/app/services/foo.rb
      #   class Foo
      #     def bar
      #       Private.my_private_api
      #     end
      #   end
      #
      #   # good
      #   # packs/foo/app/services/foo.rb
      #   class Bar
      #     def bar
      #       Bar.my_public_api
      #     end
      #   end
      #
      class Privacy < Base
        extend T::Sig

        sig { returns(T::Boolean) }
        def support_autocorrect?
          false
        end

        sig { params(node: RuboCop::AST::ConstNode).void }
        def on_const(node)
          # See https://github.com/rubocop/rubocop/blob/master/lib/rubocop/cop/lint/constant_resolution.rb source code as an example
          return if Private.partial_const_reference?(node)

          constant_reference = ConstantResolver::ConstantReference.resolve(node, processed_source)

          # If we can't determine a constant reference, we can just early return. This could be beacuse the constant is defined
          # in a gem OR because it's not abiding by the namespace convention we've established.
          return if constant_reference.nil?
          return if constant_reference.referencing_package.name == constant_reference.source_package.name

          is_new_violation = [
            !constant_reference.public_api?,
            constant_reference.source_package.enforces_privacy?,
            !Private.violation_in_package_todo_yml?(constant_reference)
          ].all?

          if is_new_violation
            add_offense(
              node.source_range,
              message: format(
                'Privacy violation detected. See https://github.com/Shopify/packwerk/blob/main/RESOLVING_VIOLATIONS.md for help'
              )
            )
          end
        end
      end
    end
  end
end
