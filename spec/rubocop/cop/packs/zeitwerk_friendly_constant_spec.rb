# typed: false

RSpec.describe RuboCop::Cop::Packs::ZeitwerkFriendlyConstant, :config do
  let(:config) do
    RuboCop::Config.new
  end

  context 'constant definition and file path respect the conventions of zeitwerk' do
    context 'a top-level constant' do
      let(:source) do
        <<~RUBY
          module Foo
          end
        RUBY
      end

      it { expect_no_offenses source, '/some/directory/foo.rb' }
    end

    context 'a multi-level constant in its own file' do
      let(:source) do
        <<~RUBY
          module Foo
            module Bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, '/some/directory/foo/bar.rb' }
    end

    context "a multi-level constant in its parent's file " do
      let(:source) do
        <<~RUBY
          module Foo
            module Bar
            end
          end
        RUBY
      end

      it { expect_no_offenses source, '/some/directory/foo.rb' }
    end
  end

  context 'constant definition and file path DO NOT respect the conventions of zeitwerk' do
    context 'a top-level constant' do
      let(:source) do
        <<~RUBY
          module Bar
          ^^^^^^^^^^ Module name does not match filename.
          end
        RUBY
      end

      it { expect_offense source, '/some/directory/foo.rb' }
    end

    context 'multi-level constants' do
      let(:source) do
        <<~RUBY
          module Foo
            module Bar
            end

            module Baz
            ^^^^^^^^^^ Module name does not match filename.
            end
          end
        RUBY
      end

      it { expect_offense source, '/some/directory/foo/bar.rb' }
    end
  end
end
