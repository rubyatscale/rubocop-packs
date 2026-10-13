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
      #   # bad - RBS signatures and Sorbet annotations are not documentation
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     # @override
      #     #: -> void
      #     def bar; end
      #   end
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     # This is a documentation comment.
      #     # @override
      #     #: -> void
      #     def bar; end
      #   end
      #
      #   # bad - rbs-inline annotations are not documentation either
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     # @rbs baz: Integer
      #     # @rbs return: void
      #     def bar(baz); end
      #   end
      #
      #   # good - an rbs-inline annotation with a `--` description is documentation
      #   # packs/foo/app/public/foo.rb
      #   class Foo
      #     # @rbs baz: Integer -- This is a documentation comment.
      #     # @rbs return: void
      #     def bar(baz); end
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
        # 2) It allows `Style/DocumentationMethod` to work with sigs, RBS comment signatures, Sorbet annotations and rbs-inline annotations as expected.
        #
        # An alternate approach would be to monkey patch the existing cop, as `rubocop-sorbet` did here:
        # https://github.com/Shopify/rubocop-sorbet/blob/6634f033611604cd76eeb73eae6d8728ec82d504/lib/rubocop/cop/sorbet/mutable_constant_sorbet_aware_behaviour.rb
        # This monkey-patched cop could/should probably be upstreamed to `rubocop-sorbet`, and then `config/default.yml` could simply set `packs/*/app/public/**/*`
        # in the default include paths. However, that strategy has the downside of resulting in more configuration for the consumer if they only want to
        # support this for some packs.

        # A `sig` block: `sig`, `sig(:final)` or `T::Sig::WithoutRuntime.sig`. These are the forms of
        # `rubocop-sorbet`'s `SignatureHelp#signature?` that sorbet-runtime defines: it also matches
        # `T::Sig.sig`, which raises a `NoMethodError`.
        SORBET_SIGNATURE = RuboCop::AST::NodePattern.new(<<~PATTERN)
          (block
            (send {nil? (const (const (const {nil? cbase} :T) :Sig) :WithoutRuntime)} :sig (sym :final)?)
            (args)
            ...)
        PATTERN

        # The lines of an RBS method signature as Sorbet reads them: `#:` starts one, and `#|` continues a
        # multi-line one. https://sorbet.org/docs/rbs-support
        RBS_SIGNATURE = /\A#[:|]/

        # The comments Sorbet reads in place of a `sig`'s modifiers, such as `# @override` for `override`,
        # plus `@without_runtime`, which `spoom srb sigs translate` writes for `T::Sig::WithoutRuntime.sig`.
        SORBET_METHOD_ANNOTATIONS = [
          '@abstract',
          '@final',
          '@overridable',
          '@override',
          '@override(allow_incompatible: true)',
          '@override(allow_incompatible: false)',
          '@override(allow_incompatible: :visibility)',
          '@without_runtime',
        ].freeze

        # An rbs-inline annotation, the indented or blank lines that continue one, and the `--` that starts
        # the description some of them take, but not a `--` inside a string literal type such as
        # `"--verbose"`. https://github.com/ruby/rbs/blob/master/docs/inline.md
        RBS_INLINE_ANNOTATION = /\A#\s*@rbs\b/
        RBS_INLINE_CONTINUATION = /\A#(\s{2,}\S|\s*\z)/
        RBS_INLINE_DESCRIPTION = /(?<!\S)--\s*\S/

        # rubocop < 1.91 checks AllowedMethods inside `#check`, which this cop
        # overrides. Drop when the gemspec floor is rubocop >= 1.91; until then the
        # minimum-rubocop CI job covers it. Re-alias `on_defs` so it binds to this
        # method, not the parent's.
        #: (RuboCop::AST::DefNode node) -> void
        def on_def(node)
          return if allowed_methods.include?(node.method_name)

          super
        end
        alias_method :on_defs, :on_def

        private

        # `node` is the enclosing send for a definition passed to `module_function` or
        # `ruby2_keywords`, and the definition itself otherwise.
        #: ((RuboCop::AST::DefNode | RuboCop::AST::SendNode) node) -> void
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
        #: ((RuboCop::AST::DefNode | RuboCop::AST::SendNode) node) -> bool
        def non_public_method?(node)
          if node.is_a?(RuboCop::AST::DefNode) && node.defs_type?
            non_public_modifier?(node.parent) || made_private_after_definition?(node)
          else
            non_public?(node)
          end
        end

        #: (RuboCop::AST::DefNode node) -> bool
        def made_private_after_definition?(node)
          node.right_siblings.any? do |sibling|
            sibling.is_a?(RuboCop::AST::SendNode) &&
              (sibling.receiver.nil? || sibling.receiver.self_type?) &&
              sibling.method?(:private_class_method) &&
              sibling.arguments.any? do |argument|
                argument.is_a?(RuboCop::AST::SymbolNode) && argument.value == node.method_name
              end
          end
        end

        #: (top node) -> bool
        def node_is_sorbet_signature?(node)
          case node
          when RuboCop::AST::Node
            !!SORBET_SIGNATURE.match(node)
          else
            # A sibling is not necessarily an AST node. It is a `Symbol` when a method definition is
            # passed to a modifier, such as the `:private` in `private def foo`.
            false
          end
        end

        # A copy of `RuboCop::Cop::DocumentationComment#documentation_comment?` with two changes. Like the
        # original, it ignores annotation keywords (`# TODO:`) and directives (`# rubocop:disable`), and it
        # also ignores RBS comments, which, like a `sig`, are not documentation, and blank comments. And it
        # reads only the comments directly above the method: the original accepts any comment above a
        # method once one is adjacent, which an RBS signature always is, so a section heading a blank line
        # above would count.
        #: (RuboCop::AST::Node node) -> bool
        def documentation_comment?(node)
          preceding_lines = preceding_lines(node)

          return false unless preceding_comment?(node, preceding_lines.last)

          comments = adjacent_comments(preceding_lines)

          (comments - rbs_comments(comments)).any? do |comment|
            !comment.text.delete_prefix('#').strip.empty? &&
              !AnnotationComment.new(comment, annotation_keywords).annotation? &&
              !interpreter_directive_comment?(comment) &&
              !rubocop_directive_comment?(comment)
          end
        end

        # The unbroken run of `comments` that ends with the last one.
        #: (Array[Parser::Source::Comment] comments) -> Array[Parser::Source::Comment]
        def adjacent_comments(comments)
          comments.chunk_while { |above, below| below.loc.line - above.loc.last_line == 1 }.to_a.last || []
        end

        # The `comments` that give the method's type rather than document it: Sorbet's signature lines and
        # method annotations, and rbs-inline's `# @rbs` annotations along with the indented or blank lines
        # that continue one, as in an overload's `#    | (Float) -> Float`. An `@rbs` annotation with a
        # `--` description, as in `# @rbs x: Integer -- the count`, is documentation, including one whose
        # description starts on the next line.
        #: (Array[Parser::Source::Comment] comments) -> Array[Parser::Source::Comment]
        def rbs_comments(comments)
          # Each comment with the indented or blank lines below it, which continue it if it is an annotation
          entries = comments.slice_before { |comment| !comment.text.match?(RBS_INLINE_CONTINUATION) }

          entries.flat_map do |entry|
            if entry.fetch(0).text.match?(RBS_INLINE_ANNOTATION)
              annotation = entry.map { |comment| comment.text.delete_prefix('#') }.join("\n")
              annotation.match?(RBS_INLINE_DESCRIPTION) ? [] : entry
            else
              entry.select do |comment|
                comment.text.match?(RBS_SIGNATURE) ||
                  SORBET_METHOD_ANNOTATIONS.include?(comment.text.delete_prefix('#').strip)
              end
            end
          end
        end
      end
    end
  end
end
