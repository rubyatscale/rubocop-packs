# typed: false

RSpec.describe RuboCop::Cop::Modularization::RequireDocumentedPublicApis, :config do
  # This is the way rubocop itself tests the Style/DocumentationMethod cop
  # https://github.com/rubocop/rubocop/blob/master/spec/rubocop/cop/style/documentation_method_spec.rb
  let(:config) do
    RuboCop::Config.new(
      'Style/CommentAnnotation' => {
        'Keywords' => %w[TODO FIXME OPTIMIZE HACK REVIEW]
      },
      'Style/DocumentationMethod' => {
        'RequireForNonPublicMethods' => true
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
end
