# typed: strict
# frozen_string_literal: true

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
      # @example RequireForNonPublicMethods: false (default)
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     private
      #
      #     def bar; end
      #   end
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     protected
      #
      #     def bar; end
      #   end
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     def self.bar; end
      #     private_class_method :bar
      #   end
      #
      #   # bad - `private` does not apply to singleton methods, so `bar` is public
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     private
      #
      #     def self.bar; end
      #   end
      #
      # @example RequireForNonPublicMethods: true
      #
      #   # bad
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     private
      #
      #     def bar; end
      #   end
      #
      #   # bad
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     protected
      #
      #     def bar; end
      #   end
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     private
      #
      #     # This is a documentation comment.
      #     def bar; end
      #   end
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     protected
      #
      #     # This is a documentation comment.
      #     def bar; end
      #   end
      #
      # @example AllowedMethods: ['method_missing', 'respond_to_missing?']
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     def method_missing(name, *args); end
      #
      #     def respond_to_missing?(symbol, include_private); end
      #   end
      #
      #   # bad
      #   # packs/foo/app/public/foo.rb
      #   class Foo
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

        # rubocop < 1.91 checks AllowedMethods inside `#check`, which this cop
        # overrides. Drop when the gemspec floor is rubocop >= 1.91; until then the
        # minimum-rubocop CI job covers it. Re-alias `on_defs` so it binds to this
        # method, not the parent's.
        sig { params(node: T.untyped).void }
        def on_def(node)
          return if allowed_methods.include?(node.method_name)

          super
        end
        alias_method :on_defs, :on_def

        sig { params(node: T.untyped).void }
        def check(node)
          # This cop only applies for ruby files in `app/public`
          return if !processed_source.file_path.include?('app/public')
          return if non_public_method?(node) && !require_for_non_public_methods?

          left_sibling = node.left_sibling

          # A `Symbol` sibling means the definition was passed to a modifier, as in
          # `private def foo` or `private_class_method def self.foo`, so both the sig and the
          # documentation comment sit above the enclosing send rather than above the definition.
          if left_sibling.is_a?(Symbol)
            if node_is_sorbet_signature?(node.parent.left_sibling)
              return if documentation_comment?(node.parent.left_sibling)
            elsif documentation_comment?(node.parent)
              return
            end
          elsif node_is_sorbet_signature?(left_sibling)
            return if documentation_comment?(node.left_sibling)
          elsif documentation_comment?(node)
            return
          end

          add_offense(node)
        end

        # `DefNode#non_public?` treats a singleton method after a bare `private` or `protected`
        # as non-public, but those only change the visibility of instance methods. A singleton
        # method is non-public only when `private_class_method` wraps it or later names it.
        sig { params(node: T.untyped).returns(T::Boolean) }
        def non_public_method?(node)
          return non_public?(node) if !node.defs_type?

          non_public_modifier?(node.parent) || made_private_after_definition?(node)
        end

        sig { params(node: T.untyped).returns(T::Boolean) }
        def made_private_after_definition?(node)
          node.right_siblings.any? do |sibling|
            sibling.is_a?(RuboCop::AST::SendNode) &&
              sibling.receiver.nil? &&
              sibling.method?(:private_class_method) &&
              sibling.arguments.any? do |argument|
                argument.is_a?(RuboCop::AST::SymbolNode) && argument.value == node.method_name
              end
          end
        end

        sig { params(node: T.untyped).returns(T::Boolean) }
        def node_is_sorbet_signature?(node)
          # A sibling is not necessarily an AST node. It is a `Symbol` when a method definition is
          # passed to a modifier, such as the `:private` in `private def foo`.
          return false if !node.is_a?(RuboCop::AST::Node)

          # A node's `source` is `nil` when it has no source range. That is the case for the empty
          # `args` node of a block written without parameters, as in `Struct.new(:a) do ... end`,
          # which is the left sibling of a method defined as the block's only statement.
          node_source = node.source

          # Is there a better way to check if a node is a sorbet signature? Probably!
          !!(node_source && (node_source.include?('sig do') || node_source.include?('sig {')))
        end
      end
    end
  end
end
