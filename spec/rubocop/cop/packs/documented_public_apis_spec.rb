# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Packs::DocumentedPublicApis, :config do
  # This is the way rubocop itself tests the Style/DocumentationMethod cop
  # https://github.com/rubocop/rubocop/blob/master/spec/rubocop/cop/style/documentation_method_spec.rb
  # RequireForNonPublicMethods is read from the cop's own config section, so it
  # must be set under Packs/DocumentedPublicApis to reach this cop.
  let(:config) do
    RuboCop::Config.new(
      'Style/CommentAnnotation' => {
        'Keywords' => %w(TODO FIXME OPTIMIZE HACK REVIEW),
      },
      'Packs/DocumentedPublicApis' => {
        'RequireForNonPublicMethods' => true,
      }
    )
  end

  context 'when class defines an instance method with no sig and no documentation' do
    let(:source) do
      <<~RUBY
        class Foo
          def bar
          ^^^^^^^ Missing method documentation comment.
          end
        end
      RUBY
    end

    it { expect_offense source, 'packs/foo/app/public/foo.rb' }
  end

  context 'when private class defines an instance method with no sig and no documentation' do
    let(:source) do
      <<~RUBY
        class Foo
          def bar
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/foo/app/service/foo.rb' }
  end

  context 'when class defines an instance method with no sig and with documentation' do
    let(:source) do
      <<~RUBY
        class Foo

          # This has documentation, cool
          def self.bar
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
  end

  context 'when class defines an instance method with a sig and no documentation' do
    let(:source) do
      <<~RUBY
        class Foo
          sig { void }
          def bar
          ^^^^^^^ Missing method documentation comment.
          end
        end
      RUBY
    end

    it { expect_offense source, 'packs/foo/app/public/foo.rb' }
  end

  context 'when class defines an instance method with a sig and with documentation below the sig' do
    let(:source) do
      <<~RUBY
        class Foo

          sig { void }
          # This has documentation, cool
          def self.bar
          ^^^^^^^^^^^^ Missing method documentation comment.
          end
        end
      RUBY
    end

    # This violates because the docs are between the sig and method
    it { expect_offense source, 'packs/foo/app/public/foo.rb' }
  end

  context 'when class defines an instance method with a single-line sig and with documentation above the sig' do
    let(:source) do
      <<~RUBY
        class Foo

          # This has documentation, cool
          sig { void }
          def self.bar
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
  end

  context 'when class defines an instance method with a multi line sig and with documentation above the sig' do
    let(:source) do
      <<~RUBY
        class Foo

          # This has documentation, cool
          sig do
            void
          end
          def self.bar
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
  end

  context 'when class defines an instance method with a final sig and no documentation' do
    let(:source) do
      <<~RUBY
        class Foo
          sig(:final) { void }
          def bar
          ^^^^^^^ Missing method documentation comment.
          end
        end
      RUBY
    end

    it { expect_offense source, 'packs/foo/app/public/foo.rb' }
  end

  context 'when class defines an instance method with a final sig and with documentation above the sig' do
    let(:source) do
      <<~RUBY
        class Foo
          # This has documentation, cool
          sig(:final) { void }
          def bar
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
  end

  context 'when class defines an instance method with a runtime-free sig and with documentation above the sig' do
    let(:source) do
      <<~RUBY
        class Foo
          # This has documentation, cool
          T::Sig::WithoutRuntime.sig { void }
          def bar
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
  end

  context 'when class defines an instance method with a top-level runtime-free sig and with documentation above the sig' do
    let(:source) do
      <<~RUBY
        class Foo
          # This has documentation, cool
          ::T::Sig::WithoutRuntime.sig { void }
          def bar
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
  end

  context 'when an undocumented method follows a block whose body contains a sig' do
    let(:source) do
      <<~RUBY
        module Foo
          # This has documentation, cool
          included do
            # This has documentation, cool
            sig { void }
            def baz
            end
          end

          def bar
          ^^^^^^^ Missing method documentation comment.
          end
        end
      RUBY
    end

    it { expect_offense source, 'packs/foo/app/public/foo.rb' }
  end

  context 'with RBS comment signatures' do
    context 'when an instance method has an RBS signature and no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            #: -> void
            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an instance method has a multi-line RBS signature and no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            #: (
            #|   Integer
            #| ) -> void
            def bar(baz)
            ^^^^^^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a singleton method has Sorbet annotations, an RBS signature and no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            # @override(allow_incompatible: true)
            # @final
            #: -> void
            def self.bar
            ^^^^^^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an instance method has every Sorbet annotation, an RBS signature and no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            # @abstract
            # @final
            # @overridable
            # @override
            # @override(allow_incompatible: true)
            # @override(allow_incompatible: false)
            # @override(allow_incompatible: :visibility)
            # @without_runtime
            #: -> void
            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an instance method has a YARD tag with a description and an RBS signature' do
      let(:source) do
        <<~RUBY
          class Foo
            # @abstract Subclasses must implement this.
            #: -> void
            def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an instance method has a rubocop directive, an RBS signature and no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            # rubocop:disable Style/For
            #: -> void
            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an instance method has an annotation keyword, an RBS signature and no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            # TODO: Document this
            #: -> void
            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an instance method has documentation above Sorbet annotations and an RBS signature' do
      let(:source) do
        <<~RUBY
          class Foo
            # This has documentation, cool
            # @override
            #: -> void
            def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an instance method has documentation between the RBS signature and the method' do
      let(:source) do
        <<~RUBY
          class Foo
            #: -> void
            # This has documentation, cool
            def bar
            end
          end
        RUBY
      end

      # Sorbet ignores other comments when it pairs an RBS signature with its method, so documentation can
      # sit between them. Documentation below a `sig` doesn't count, since the cop reads it above the `sig`.
      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a comment is separated from an RBS signature by a blank line' do
      let(:source) do
        <<~RUBY
          class Foo
            # == Helpers

            #: -> void
            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an instance method has only a Sorbet annotation above its sig' do
      let(:source) do
        <<~RUBY
          class Foo
            # @override
            sig { override.void }
            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an undocumented method with an RBS signature uses the private modifier' do
      let(:source) do
        <<~RUBY
          class Foo
            #: -> void
            private def bar
                    ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a documented method with an RBS signature uses the private modifier' do
      let(:source) do
        <<~RUBY
          class Foo
            # Here is documentation!
            #: -> void
            private def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end
  end

  context 'using inline private class method syntax' do
    context 'with a sig' do
      context 'documented' do
        let(:source) do
          <<~RUBY
            class Foo
              # Here is documentation!
              sig { void }
              private_class_method def self.bar
              end
            end
          RUBY
        end

        it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
      end

      context 'undocumented' do
        let(:source) do
          <<~RUBY
            class Foo
              sig { void }
              private_class_method def self.bar
                                   ^^^^^^^^^^^^ Missing method documentation comment.
              end
            end
          RUBY
        end

        it { expect_offense source, 'packs/foo/app/public/foo.rb' }
      end
    end

    context 'with no sig' do
      context 'documented' do
        let(:source) do
          <<~RUBY
            class Foo
              # Here is documentation!
              private_class_method def self.bar
              end
            end
          RUBY
        end

        it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
      end

      context 'undocumented' do
        let(:source) do
          <<~RUBY
            class Foo
              private_class_method def self.bar
                                   ^^^^^^^^^^^^ Missing method documentation comment.
              end
            end
          RUBY
        end

        it { expect_offense source, 'packs/foo/app/public/foo.rb' }
      end
    end
  end

  context 'using inline private instance method syntax' do
    context 'with a sig' do
      context 'documented' do
        let(:source) do
          <<~RUBY
            class Foo
              # Here is documentation!
              sig { void }
              private def bar
              end
            end
          RUBY
        end

        it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
      end

      context 'undocumented' do
        let(:source) do
          <<~RUBY
            class Foo
              sig { void }
              private def bar
                      ^^^^^^^ Missing method documentation comment.
              end
            end
          RUBY
        end

        it { expect_offense source, 'packs/foo/app/public/foo.rb' }
      end
    end

    context 'with no sig' do
      context 'documented' do
        let(:source) do
          <<~RUBY
            class Foo
              # Here is documentation!
              private def bar
              end
            end
          RUBY
        end

        it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
      end

      context 'undocumented' do
        let(:source) do
          <<~RUBY
            class Foo
              private def bar
                      ^^^^^^^ Missing method documentation comment.
              end
            end
          RUBY
        end

        it { expect_offense source, 'packs/foo/app/public/foo.rb' }
      end
    end
  end

  context 'when a method is defined inside a block' do
    context 'when the block takes no parameters and the method is undocumented' do
      let(:source) do
        <<~RUBY
          Foo = Struct.new(:a) do
            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when the block takes no parameters and the method is documented' do
      let(:source) do
        <<~RUBY
          Foo = Struct.new(:a) do
            # This has documentation, cool
            def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when the method has a sig and documentation above the sig' do
      let(:source) do
        <<~RUBY
          Foo = Data.define(:a) do
            # This has documentation, cool
            sig { void }
            def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when the method has a sig and no documentation' do
      let(:source) do
        <<~RUBY
          Foo = Data.define(:a) do
            sig { void }
            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when the block takes parameters' do
      let(:source) do
        <<~RUBY
          Foo = Struct.new(:a) do |klass|
            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end
  end

  context 'when RequireForNonPublicMethods is true' do
    context 'when a private section precedes an undocumented instance method' do
      let(:source) do
        <<~RUBY
          class Foo
            private

            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a protected section precedes an undocumented instance method' do
      let(:source) do
        <<~RUBY
          class Foo
            protected

            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a private section precedes an undocumented sig and instance method' do
      let(:source) do
        <<~RUBY
          class Foo
            private

            sig { void }
            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a private section in a singleton class precedes an undocumented instance method' do
      let(:source) do
        <<~RUBY
          class Foo
            class << self
              private

              def bar
              ^^^^^^^ Missing method documentation comment.
              end
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a private section precedes a documented instance method with a sig' do
      let(:source) do
        <<~RUBY
          class Foo
            private

            # Here is documentation!
            sig { void }
            def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a private section precedes an undocumented singleton method' do
      let(:source) do
        <<~RUBY
          class Foo
            private

            def self.bar
            ^^^^^^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when private_class_method names an undocumented singleton method after its definition' do
      let(:source) do
        <<~RUBY
          class Foo
            def self.bar
            ^^^^^^^^^^^^ Missing method documentation comment.
            end
            private_class_method :bar
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end
  end

  context 'when RequireForNonPublicMethods is not configured' do
    let(:config) do
      RuboCop::Config.new(
        'Style/CommentAnnotation' => {
          'Keywords' => %w(TODO FIXME OPTIMIZE HACK REVIEW),
        }
      )
    end

    context 'when a public method has no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a private section precedes an undocumented instance method' do
      let(:source) do
        <<~RUBY
          class Foo
            private

            def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a private section precedes an undocumented sig and instance method' do
      let(:source) do
        <<~RUBY
          class Foo
            private

            sig { void }
            def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a protected section precedes an undocumented instance method' do
      let(:source) do
        <<~RUBY
          class Foo
            protected

            def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a private section precedes an undocumented method in a singleton class block' do
      let(:source) do
        <<~RUBY
          class Foo
            class << self
              private

              def bar
              end
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a private section precedes an undocumented sig and method in a singleton class block' do
      let(:source) do
        <<~RUBY
          class Foo
            class << self
              private

              sig { void }
              def bar
              end
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an undocumented instance method uses the private modifier' do
      let(:source) do
        <<~RUBY
          class Foo
            private def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an undocumented singleton method uses the private_class_method modifier' do
      let(:source) do
        <<~RUBY
          class Foo
            private_class_method def self.bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a private section is followed by a public section and an undocumented instance method' do
      let(:source) do
        <<~RUBY
          class Foo
            private

            public

            def bar
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an undocumented instance method uses the protected modifier' do
      let(:source) do
        <<~RUBY
          class Foo
            protected def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an undocumented method uses the module_function modifier' do
      let(:source) do
        <<~RUBY
          module Foo
            module_function def bar
            ^^^^^^^^^^^^^^^^^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a documented method uses the module_function modifier' do
      let(:source) do
        <<~RUBY
          module Foo
            # Here is documentation!
            module_function def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    # A bare `private` or `protected` only changes the visibility of instance
    # methods, so a singleton method defined after one is still public.
    context 'when a private section precedes an undocumented singleton method' do
      let(:source) do
        <<~RUBY
          class Foo
            private

            def self.bar
            ^^^^^^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a protected section precedes an undocumented singleton method' do
      let(:source) do
        <<~RUBY
          class Foo
            protected

            def self.bar
            ^^^^^^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when private_class_method names an undocumented singleton method after its definition' do
      let(:source) do
        <<~RUBY
          class Foo
            def self.bar
            end
            private_class_method :bar
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when self.private_class_method names an undocumented singleton method after its definition' do
      let(:source) do
        <<~RUBY
          class Foo
            def self.bar
            end
            self.private_class_method :bar
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when private_class_method names several methods including an undocumented singleton method' do
      let(:source) do
        <<~RUBY
          class Foo
            sig { void }
            def self.bar
            end

            # Here is documentation!
            def self.baz
            end

            private_class_method :baz, :bar
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when private_class_method names a different method than an undocumented singleton method' do
      let(:source) do
        <<~RUBY
          class Foo
            def self.bar
            ^^^^^^^^^^^^ Missing method documentation comment.
            end

            # Here is documentation!
            def self.baz
            end
            private_class_method :baz
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end
  end

  context 'when AllowedMethods is configured' do
    let(:config) do
      RuboCop::Config.new(
        'Style/CommentAnnotation' => {
          'Keywords' => %w(TODO FIXME OPTIMIZE HACK REVIEW),
        },
        'Packs/DocumentedPublicApis' => {
          'AllowedMethods' => %w(bar),
          'RequireForNonPublicMethods' => true,
        }
      )
    end

    context 'when an allowed instance method has no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an allowed private instance method has no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            private

            def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an instance method outside AllowedMethods has no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            def baz
            ^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when an allowed singleton method has no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            def self.bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end

    context 'when a singleton method outside AllowedMethods has no documentation' do
      let(:source) do
        <<~RUBY
          class Foo
            def self.baz
            ^^^^^^^^^^^^ Missing method documentation comment.
            end
          end
        RUBY
      end

      it { expect_offense source, 'packs/foo/app/public/foo.rb' }
    end
  end

  context 'when RequireForNonPublicMethods is false' do
    let(:config) do
      RuboCop::Config.new(
        'Style/CommentAnnotation' => {
          'Keywords' => %w(TODO FIXME OPTIMIZE HACK REVIEW),
        },
        'Packs/DocumentedPublicApis' => {
          'RequireForNonPublicMethods' => false,
        }
      )
    end

    context 'when a private section precedes an undocumented instance method' do
      let(:source) do
        <<~RUBY
          class Foo
            private

            def bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, 'packs/foo/app/public/foo.rb' }
    end
  end
end
