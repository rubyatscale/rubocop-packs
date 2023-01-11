# typed: strict

module RuboCop
  module Cop
    module Packs
      # This cop helps ensure that each pack has a documented public API
      # The following examples assume this basic setup.
      #
      # @example
      #
      #   # bad
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     def bar; end
      #   end
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     # This is a documentation comment.
      #     def bar; end
      #   end
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     # This is a documentation comment.
      #     # It should appear above a sorbet type signature
      #     sig { void }
      #     def bar; end
      #   end
      #
      class DocumentedPublicApis < Style::DocumentationMethod
        # This cop does two things:
        # 1) It only activates for things in the public folder
        # 2) It allows `Style/DocumentationMethod` to work with sigs as expected.
        #
        # An alternate approach would be to monkey patch the existing cop, as `rubocop-sorbet` did here:
        # https://github.com/Shopify/rubocop-sorbet/blob/6634f033611604cd76eeb73eae6d8728ec82d504/lib/rubocop/cop/sorbet/mutable_constant_sorbet_aware_behaviour.rb
        # This monkey-patched cop could/should probably be upstreamed to `rubocop-sorbet`, and then `config/default.yml` could simply set `packs/*/app/public/**/*`
        # in the default include paths. However, that strategy has the downside of resulting in more configuration for the consumer if they only want to
        # support this for some packs.
        extend T::Sig

        sig { returns(T::Boolean) }
        def support_autocorrect?
          false
        end

        sig { params(node: T.untyped).void }
        def check(node)
          # This cop only applies for ruby files in `app/public`
          return if !processed_source.file_path.include?('app/public')
          return if non_public?(node) && !require_for_non_public_methods?

          left_sibling = node.left_sibling

          if left_sibling == :private_class_method
            if node_is_sorbet_signature?(node.parent.left_sibling)
              return if documentation_comment?(node.parent.left_sibling)
            else
              return if documentation_comment?(node.parent)
            end
          elsif node_is_sorbet_signature?(left_sibling)
            return if documentation_comment?(node.left_sibling)
          elsif documentation_comment?(node)
            return
          end

          add_offense(node)
        end

        sig { params(node: T.untyped).returns(T::Boolean) }
        def node_is_sorbet_signature?(node)
          # Is there a better way to check if a node is a sorbet signature? Probably!
          !!(node && (node.source.include?('sig do') || node.source.include?('sig {')))
        end
      end
    end
  end
end
