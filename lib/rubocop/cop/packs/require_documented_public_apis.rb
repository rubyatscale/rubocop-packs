# typed: strict

module RuboCop
  module Cop
    module Packs
      class RequireDocumentedPublicApis < Style::DocumentationMethod
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
          left_sibling_is_sig = left_sibling && (left_sibling.source.include?('sig do') || left_sibling.source.include?('sig {'))
          # Is there a better way to check if the left sibling is a sorbet signature? Probably!
          if left_sibling_is_sig
            return if documentation_comment?(node.left_sibling)
          elsif documentation_comment?(node)
            return
          end

          add_offense(node)
        end
      end
    end
  end
end
